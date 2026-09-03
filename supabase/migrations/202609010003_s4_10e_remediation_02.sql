-- S4-10E REMEDIATION 02: fix the one remaining defect confirmed by
-- independent re-audit against 202609010002. Forward migration only --
-- 202609010001 and 202609010002 stay exactly as deployed.
--
-- Root cause: submit_public_order's INSERT exception handler caught the
-- generic `unique_violation` class and unconditionally treated it as an
-- idempotent replay, assuming the only unique constraint that could ever
-- fire there was (business_id, submission_idempotency_key). But `orders`
-- carries other unique constraints too (e.g. public_ref). A collision on
-- ANY of them raises the same generic unique_violation, and the handler's
-- business-scoped idempotency lookup then correctly finds no matching row
-- for that unrelated cause -- yet it still unconditionally returned
-- {replay: true, order_reference: null}, a broken response that is not a
-- real order and not a real replay.
--
-- Fix: only report a replay when the idempotency lookup genuinely resolves
-- a real existing row for the exact (business_id, submission_idempotency_key)
-- scope. If it does not, re-raise the original exception (bare `raise;`)
-- instead of manufacturing a false-success response. This changes nothing
-- about the already-passed business-scoped unique index or the legitimate
-- concurrent-retry replay path -- it only closes the gap where an
-- unrelated collision was being silently swallowed and misreported.
create or replace function public.submit_public_order(
  p_token text,
  p_items jsonb,
  p_customer_name text,
  p_customer_phone text,
  p_delivery_address text,
  p_delivery_notes text default '',
  p_idempotency_key uuid default null
) returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  rl_key text;
  allowed boolean;
  page public.public_order_pages;
  existing public.orders;
  item jsonb;
  item_count int := 0;
  merged jsonb := '{}'::jsonb; -- product_id::text -> quantity, dedupes+sums client duplicate lines
  pid uuid; qty int;
  snapshot jsonb := '[]'::jsonb;
  prod record;
  o public.orders;
  t text;
begin
  rl_key := encode(digest(coalesce(p_token, ''), 'sha256'), 'hex');

  begin
    allowed := public.check_rate_limit(rl_key, 'submit_public_order', 60, 5);
  exception when others then
    allowed := true;
  end;
  if not allowed then raise exception 'rate limited'; end if;

  select pop.* into page
    from public.public_order_pages pop
    where pop.access_token_hash = rl_key and pop.enabled = true;
  if page.id is null then
    perform public.record_invalid_lookup_telemetry('submit_public_order');
    raise exception 'invalid or unavailable order page';
  end if;

  if p_idempotency_key is null then
    raise exception 'invalid idempotency key';
  end if;

  -- Idempotent replay: same business, same key, prior order returned as-is.
  -- The raw tracking token was only ever available at original creation
  -- time (only its hash is stored), so a replay cannot re-reveal it.
  select * into existing from public.orders
    where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
  if existing.id is not null then
    return jsonb_build_object('order_reference', existing.public_ref, 'tracking_token', null, 'replay', true);
  end if;

  if p_customer_name is null or char_length(btrim(p_customer_name)) not between 1 and 120 then
    raise exception 'invalid customer name';
  end if;
  if p_customer_phone is null or char_length(btrim(p_customer_phone)) not between 1 and 30 then
    raise exception 'invalid customer phone';
  end if;
  if p_delivery_address is null or char_length(btrim(p_delivery_address)) not between 1 and 500 then
    raise exception 'invalid delivery address';
  end if;
  if p_delivery_notes is not null and char_length(p_delivery_notes) > 500 then
    raise exception 'invalid delivery notes';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 20 then
    raise exception 'invalid item list';
  end if;

  for item in select * from jsonb_array_elements(p_items) loop
    item_count := item_count + 1;
    if jsonb_typeof(item) <> 'object' or not (item ? 'product_id') or not (item ? 'quantity') then
      raise exception 'malformed order item';
    end if;
    begin
      pid := (item->>'product_id')::uuid;
    exception when others then
      raise exception 'malformed order item';
    end;
    if jsonb_typeof(item->'quantity') <> 'number' or (item->>'quantity') !~ '^[0-9]+$' then
      raise exception 'invalid quantity';
    end if;
    qty := (item->>'quantity')::int;
    if qty < 1 or qty > 50 then raise exception 'invalid quantity'; end if;
    merged := jsonb_set(merged, array[pid::text], to_jsonb(coalesce((merged->>(pid::text))::int, 0) + qty));
  end loop;

  -- Aggregate-quantity gate: the same 1..50 authoritative bound applies to
  -- each product's FINAL merged quantity, not just each individually-
  -- submitted line.
  for pid, qty in select key::uuid, value::int from jsonb_each_text(merged) loop
    if qty < 1 or qty > 50 then raise exception 'invalid quantity'; end if;
  end loop;

  for pid, qty in select key::uuid, value::int from jsonb_each_text(merged) loop
    select p.id, p.name, p.display_price into prod
      from public.products p
      where p.id = pid and p.business_id = page.business_id and p.status = 'active' and p.archived_at is null;
    if prod.id is null then
      raise exception 'product not available';
    end if;
    snapshot := snapshot || jsonb_build_array(jsonb_build_object(
      'product_id', prod.id,
      'product_name_snapshot', prod.name,
      'display_price_snapshot', prod.display_price,
      'quantity', qty,
      'line_subtotal_snapshot', round(prod.display_price * qty, 2)
    ));
  end loop;

  begin
    insert into public.orders(
      business_id, customer_name, customer_phone, delivery_address, notes,
      items, origin, submission_idempotency_key
    ) values (
      page.business_id, btrim(p_customer_name), btrim(p_customer_phone), btrim(p_delivery_address),
      coalesce(btrim(p_delivery_notes), ''), snapshot, 'public', p_idempotency_key
    ) returning * into o;
  exception when unique_violation then
    -- A unique_violation here is NOT necessarily our own idempotency key
    -- colliding (a genuine concurrent retry) -- `orders` carries other
    -- unique constraints (e.g. public_ref) that could just as easily be
    -- the actual cause. Only ever report a replay when a real row can be
    -- resolved for the exact authoritative (business_id, key) scope;
    -- otherwise this is a different, unrelated failure and must propagate
    -- as a real error, never a manufactured success.
    select * into o from public.orders
      where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
    if o.id is null then
      raise;
    end if;
    return jsonb_build_object('order_reference', o.public_ref, 'tracking_token', null, 'replay', true);
  end;

  insert into public.delivery_stops(business_id, order_id) values (page.business_id, o.id);
  t := encode(gen_random_bytes(32), 'hex');
  insert into public.tracking_tokens(order_id, token_hash) values (o.id, encode(digest(t, 'sha256'), 'hex'));
  insert into public.delivery_events(business_id, order_id, event_type, to_status, actor_role)
    values (page.business_id, o.id, 'delivery.created', 'created', 'customer');

  return jsonb_build_object('order_reference', o.public_ref, 'tracking_token', t, 'replay', false);
end;
$$;
