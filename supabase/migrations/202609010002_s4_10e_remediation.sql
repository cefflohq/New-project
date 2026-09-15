-- S4-10E REMEDIATION: fixes for 5 closure blockers found by independent
-- audit against the already-deployed 202609010001 contract. This is a
-- forward migration, not a rewrite -- 202609010001 stays exactly as it was
-- applied to staging (historical baseline), and every change here is
-- additive/corrective on top of it via `create or replace` / a new index,
-- never a retroactive edit of that file's applied history.
--
-- No new parallel status machine is introduced anywhere in this migration.
-- decline_order's existing delivery_status='cancelled' terminal state (from
-- 202609010001) is reused as the sole signal the two lifecycle-boundary
-- fixes below key off.

-- ===================== BLOCKER 1: terminal decline must be terminal =====================
-- approve_order previously only checked "already approved" (a harmless
-- no-op re-approve) and never checked for a *declined* order, so a
-- cancelled order could still be approved, and once approved_at was set,
-- assign_rider's own precondition ("order not approved") no longer blocked
-- it -- the terminal decline became reversible. Fix both boundaries: reject
-- a cancelled order at approval (closing the path that lets approved_at
-- ever become non-null on a declined order) AND, as a direct/defensive
-- second gate rather than relying solely on the transitive effect, reject
-- a cancelled order at assignment too. Every other line of both functions
-- is byte-identical to the currently-deployed version.
create or replace function public.approve_order(p_order_id uuid) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.delivery_status = 'cancelled' then
    raise exception 'order cancelled';
  end if;
  if o.approved_at is not null then
    return o;
  end if;
  update orders set approved_at = now(), approved_by = auth.uid(), updated_at = now()
    where id = o.id
    returning * into o;
  insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role)
    values (o.business_id, o.id, 'order.approved', auth.uid(), 'vendor');
  return o;
end;
$$;

create or replace function public.assign_rider(p_order_id uuid,p_rider_id uuid) returns public.orders language plpgsql security definer set search_path=public as $$declare o orders;a rider_assignments;begin select * into o from orders where id=p_order_id for update;if o.id is null or not is_business_member(o.business_id) then raise exception 'forbidden';end if;if o.delivery_status='cancelled' then raise exception 'order cancelled';end if;if o.approved_at is null then raise exception 'order not approved';end if;if not exists(select 1 from riders where id=p_rider_id and business_id=o.business_id and status='active') then raise exception 'invalid rider';end if;insert into rider_assignments(business_id,delivery_session_id,rider_id) values(o.business_id,o.delivery_session_id,p_rider_id) returning * into a;update orders set assigned_rider_id=p_rider_id,updated_at=now() where id=o.id returning * into o;update delivery_stops set assignment_id=a.id,rider_id=p_rider_id,updated_at=now() where order_id=o.id;insert into delivery_events(business_id,order_id,delivery_stop_id,assignment_id,event_type,actor_user_id,actor_role) select o.business_id,o.id,s.id,a.id,'rider.assigned',auth.uid(),'vendor' from delivery_stops s where s.order_id=o.id;return o;end$$;

-- ===================== BLOCKER 3: idempotency must be business-scoped =====================
-- submit_public_order's own replay lookup was already business-scoped
-- (`where submission_idempotency_key = ... and business_id = ...`), but the
-- partial unique index backing it was global on the key alone. Two
-- different businesses legitimately reusing the same client-generated UUID
-- collided at the index level; the ON unique_violation fallback then
-- re-ran that same business-scoped lookup, found no row (the colliding row
-- belonged to the OTHER business), and returned a reply with a null
-- order_reference instead of either business's real order. Replacing the
-- index with a (business_id, submission_idempotency_key) composite makes
-- the uniqueness boundary match the lookup boundary exactly.
drop index if exists public.orders_submission_idempotency_key_idx;

create unique index orders_business_submission_idempotency_key_idx
  on public.orders (business_id, submission_idempotency_key)
  where submission_idempotency_key is not null;

-- ===================== BLOCKER 2 + 4: submission validation ordering =====================
-- Full replace of submit_public_order fixing two independent gaps:
--   (4) p_idempotency_key was optional (default null) and only guarded the
--       replay lookup with `if ... is not null` -- a null key skipped
--       replay detection entirely and (pre-Blocker-3-fix) the old partial
--       index excluded nulls too, so a null-keyed retry could always
--       create a second order. A public submission now requires a real
--       non-null key, rejected before any read/write of the orders table.
--       A malformed (non-UUID) value is already rejected earlier still, by
--       Postgres itself, because the parameter is typed `uuid` not `text`.
--   (2) each line's quantity was bounds-checked individually (1..50)
--       BEFORE duplicate product_id lines were merged, so N duplicate
--       lines each individually valid (e.g. 20 * qty 50) could merge into
--       a single aggregate quantity (1000) that was never itself checked
--       against the same bound. The merge step is now followed by its own
--       explicit aggregate-bound pass, before any product is resolved or
--       priced, per the required parse -> validate shape -> aggregate ->
--       validate aggregate -> resolve -> snapshot sequence.
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

  -- Aggregate-quantity gate (Blocker 2): the same 1..50 authoritative bound
  -- applies to each product's FINAL merged quantity, not just each
  -- individually-submitted line.
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
    -- Genuine concurrent retry raced past the earlier check-first lookup.
    -- The unique index is now (business_id, key)-scoped, so a collision
    -- here can only ever be THIS business's own prior row.
    select * into o from public.orders
      where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
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

-- ===================== BLOCKER 5: public image assurance =====================
-- S4-10B's own storage layout comment states the prepared derivative
-- "only ever reaches the public bucket at Vendor-approval time", but
-- approve_product_media (S4-10B, closed, NOT modified here) only ever
-- flips product_media.status to 'approved' -- it never itself copies or
-- verifies an object landing in cefflo-product-display; that bucket's
-- write RLS policy (also S4-10B, unmodified) exists to let a client/worker
-- place the object there as a *separate* step. status='approved' therefore
-- records Vendor intent, not confirmed public existence. This is an
-- additive S4-10E-side assurance boundary only: no S4-10B table, function,
-- policy, or bucket is changed. public_order_catalog now requires a live,
-- indexed (bucket_id, name) existence check against storage.objects for
-- cefflo-product-display before it will ever hand back an image_url; an
-- 'approved' row whose object was never actually placed there now
-- correctly yields image_url = null instead of a broken/guessed link.
create or replace function public.public_order_catalog(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  key text;
  allowed boolean;
  page public.public_order_pages;
  result jsonb;
  display_bucket_url text := '/storage/v1/object/public/cefflo-product-display/';
begin
  key := encode(digest(coalesce(p_token, ''), 'sha256'), 'hex');

  begin
    allowed := public.check_rate_limit(key, 'public_order_catalog', 60, 10);
  exception when others then
    allowed := true;
  end;
  if not allowed then raise exception 'rate limited'; end if;

  select pop.* into page
    from public.public_order_pages pop
    where pop.access_token_hash = key and pop.enabled = true;

  if page.id is null then
    perform public.record_invalid_lookup_telemetry('public_order_catalog');
    return null;
  end if;

  select jsonb_build_object(
    'business', jsonb_build_object('name', b.name),
    'categories', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name) order by c.sort_order, c.id)
      from public.product_categories c
      where c.business_id = page.business_id and c.archived_at is null
    ), '[]'::jsonb),
    'products', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'category_id', p.category_id,
        'name', p.name,
        'description', p.description,
        'display_price', p.display_price,
        'image_url', (
          select display_bucket_url || pm.prepared_storage_path
          from public.product_media pm
          where pm.product_id = p.id and pm.status = 'approved' and pm.archived_at is null
            and exists (
              select 1 from storage.objects so
              where so.bucket_id = 'cefflo-product-display' and so.name = pm.prepared_storage_path
            )
          limit 1
        )
      ) order by p.sort_order, p.id)
      from public.products p
      where p.business_id = page.business_id and p.status = 'active' and p.archived_at is null
    ), '[]'::jsonb)
  ) into result
  from public.businesses b
  where b.id = page.business_id;

  return result;
end;
$$;
