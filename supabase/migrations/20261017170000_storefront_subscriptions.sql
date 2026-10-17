-- Storefront subscriptions + vendor delivery settings in get_storefront.
-- Rollback: unschedule cron 'storefront-subscriptions'; drop the two subscription tables and functions; restore get_storefront / submit_storefront_order (without p_plan).
-- Storefront subscriptions (Founder 2026-10-17): a package is paid in full;
-- deliveries follow the chosen weekdays for N weeks, only on days the store
-- delivers; a day can be skipped, moved or doubled within the same month.
create table if not exists public.storefront_subscriptions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  first_order_id uuid references public.orders(id) on delete set null,
  customer_name text not null, customer_phone text not null, delivery_address text not null,
  delivery_notes text not null default '', latitude double precision, longitude double precision,
  items jsonb not null, days smallint[] not null, weeks smallint not null check (weeks between 1 and 4),
  shift jsonb, delivery_fee numeric(10,2),
  status text not null default 'active' check (status in ('active', 'cancelled', 'completed')),
  created_at timestamptz not null default now()
);
create table if not exists public.storefront_subscription_days (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.storefront_subscriptions(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  delivery_on date not null,
  multiplier smallint not null default 1 check (multiplier between 1 and 3),
  status text not null default 'scheduled' check (status in ('scheduled', 'skipped', 'ordered')),
  order_id uuid references public.orders(id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (subscription_id, delivery_on)
);
create index if not exists storefront_subscription_days_due on public.storefront_subscription_days (delivery_on) where status = 'scheduled';
alter table public.storefront_subscriptions enable row level security;
alter table public.storefront_subscription_days enable row level security;
drop policy if exists storefront_subscriptions_member_read on public.storefront_subscriptions;
create policy storefront_subscriptions_member_read on public.storefront_subscriptions for select to authenticated using (is_business_member(business_id));
drop policy if exists storefront_subscription_days_member_read on public.storefront_subscription_days;
create policy storefront_subscription_days_member_read on public.storefront_subscription_days for select to authenticated using (is_business_member(business_id));
revoke all on public.storefront_subscriptions, public.storefront_subscription_days from anon;
grant select on public.storefront_subscriptions, public.storefront_subscription_days to authenticated;

-- Malaysia business day.
create or replace function public._my_today() returns date language sql stable as $$ select (now() at time zone 'Asia/Kuala_Lumpur')::date $$;

create or replace function public._start_storefront_subscription(page public_order_pages, p_plan jsonb, p_items jsonb,
  p_name text, p_phone text, p_address text, p_notes text, p_lat double precision, p_lng double precision, p_key uuid)
returns uuid language plpgsql security definer set search_path to 'public' as $$
declare sub_id uuid; w int; d smallint[]; dt date; first_order uuid; open_days int[]; n int := 0;
begin
  w := (p_plan->>'weeks')::int;
  if w not in (select unnest(page.package_weeks)) then raise exception 'invalid package'; end if;
  select array_agg(x::smallint order by x) into d from jsonb_array_elements_text(p_plan->'days') x
   where x::int = any(page.delivery_days);
  if d is null or cardinality(d) = 0 then raise exception 'invalid delivery days'; end if;
  select array_agg(h.weekday) into open_days from business_hours h where h.business_id = page.business_id and h.is_open;
  select id into first_order from orders where business_id = page.business_id and submission_idempotency_key = p_key;
  insert into storefront_subscriptions(business_id, first_order_id, customer_name, customer_phone, delivery_address,
      delivery_notes, latitude, longitude, items, days, weeks, shift, delivery_fee)
    values (page.business_id, first_order, btrim(p_name), btrim(p_phone), btrim(p_address), coalesce(btrim(p_notes), ''),
      p_lat, p_lng, p_items, d, w,
      (select s from jsonb_array_elements(page.delivery_shifts) s where s->>'name' = p_plan->>'shift' limit 1),
      page.delivery_fee)
    returning id into sub_id;
  -- Deliveries over the next w weeks on the chosen weekdays the store is open.
  for dt in select g::date from generate_series(_my_today(), _my_today() + (w * 7 - 1), interval '1 day') g loop
    if extract(isodow from dt)::smallint = any(d) and (open_days is null or extract(isodow from dt)::int = any(open_days)) then
      n := n + 1;
      insert into storefront_subscription_days(subscription_id, business_id, delivery_on, status, order_id)
        values (sub_id, page.business_id, dt, case when n = 1 then 'ordered' else 'scheduled' end, case when n = 1 then first_order end);
    end if;
  end loop;
  return sub_id;
end $$;
revoke all on function public._start_storefront_subscription(public_order_pages, jsonb, jsonb, text, text, text, text, double precision, double precision, uuid) from public, anon, authenticated;

-- Daily: create today's orders for active subscriptions.
create or replace function public.storefront_subscription_tick() returns int
language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare r record; page public_order_pages; items jsonb; res jsonb; made int := 0; oid uuid;
begin
  for r in select sd.*, s.customer_name, s.customer_phone, s.delivery_address, s.delivery_notes, s.latitude, s.longitude, s.items as s_items
             from storefront_subscription_days sd join storefront_subscriptions s on s.id = sd.subscription_id
            where sd.status = 'scheduled' and sd.delivery_on <= _my_today() and s.status = 'active' for update of sd skip locked loop
    select * into page from public_order_pages where business_id = r.business_id;
    select jsonb_agg(jsonb_build_object('product_id', i->'product_id', 'quantity', least(50, (i->>'quantity')::int * r.multiplier))) into items
      from jsonb_array_elements(r.s_items) i;
    begin
      res := _create_public_order(page, items, r.customer_name, r.customer_phone, r.delivery_address,
        left(r.delivery_notes || E'\n' || 'Subscription delivery ' || to_char(r.delivery_on, 'Dy DD Mon'), 500),
        md5(r.id::text)::uuid);
      select id into oid from orders where business_id = r.business_id and submission_idempotency_key = md5(r.id::text)::uuid;
      if r.latitude is not null then
        update orders set latitude = r.latitude, longitude = r.longitude, location_status = 'resolved',
          location_provider = 'customer_pin', location_source = 'map', location_resolved_at = now() where id = oid;
      end if;
      update storefront_subscription_days set status = 'ordered', order_id = oid, updated_at = now() where id = r.id;
      made := made + 1;
    exception when others then
      insert into delivery_events(business_id, event_type, actor_role, metadata)
        values (r.business_id, 'subscription.order_failed', 'system', jsonb_build_object('day_id', r.id, 'error', sqlerrm));
    end;
  end loop;
  update storefront_subscriptions s set status = 'completed'
   where status = 'active' and not exists (select 1 from storefront_subscription_days d where d.subscription_id = s.id and d.status = 'scheduled');
  return made;
end $$;
revoke all on function public.storefront_subscription_tick() from public, anon, authenticated;

-- Vendor: list, skip, move (same month; onto a taken day = double), cancel.
create or replace function public.list_storefront_subscriptions(p_business_id uuid) returns jsonb
language sql stable security definer set search_path to 'public' as $$
  select case when not is_business_member(p_business_id) then null else coalesce(jsonb_agg(jsonb_build_object(
    'id', s.id, 'customer_name', s.customer_name, 'customer_phone', s.customer_phone, 'delivery_address', s.delivery_address,
    'items', s.items, 'days', to_jsonb(s.days), 'weeks', s.weeks, 'shift', s.shift, 'delivery_fee', s.delivery_fee,
    'status', s.status, 'created_at', s.created_at,
    'deliveries', (select jsonb_agg(jsonb_build_object('id', d.id, 'date', d.delivery_on, 'status', d.status, 'multiplier', d.multiplier) order by d.delivery_on)
                     from storefront_subscription_days d where d.subscription_id = s.id)
  ) order by s.created_at desc), '[]'::jsonb) end
  from storefront_subscriptions s where s.business_id = p_business_id
$$;
grant execute on function public.list_storefront_subscriptions(uuid) to authenticated;

create or replace function public.change_subscription_day(p_day_id uuid, p_action text, p_new_date date default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare d storefront_subscription_days; tgt storefront_subscription_days;
begin
  select * into d from storefront_subscription_days where id = p_day_id for update;
  if d.id is null or not is_business_operational(d.business_id) then raise exception 'forbidden'; end if;
  if d.status <> 'scheduled' then raise exception 'delivery already sent or skipped'; end if;
  if p_action = 'skip' then
    update storefront_subscription_days set status = 'skipped', updated_at = now() where id = d.id;
  elsif p_action = 'move' then
    if p_new_date is null or p_new_date <= _my_today() or date_trunc('month', p_new_date) <> date_trunc('month', d.delivery_on) then
      raise exception 'move within the same month, after today';
    end if;
    select * into tgt from storefront_subscription_days where subscription_id = d.subscription_id and delivery_on = p_new_date for update;
    if tgt.id is not null then
      if tgt.status <> 'scheduled' then raise exception 'that day is not available'; end if;
      update storefront_subscription_days set multiplier = least(3, multiplier + d.multiplier), updated_at = now() where id = tgt.id;
      update storefront_subscription_days set status = 'skipped', updated_at = now() where id = d.id;
    else
      update storefront_subscription_days set delivery_on = p_new_date, updated_at = now() where id = d.id;
    end if;
  else
    raise exception 'invalid action';
  end if;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (d.business_id, 'subscription.day_' || p_action, auth.uid(), 'vendor', jsonb_build_object('day_id', d.id, 'to', p_new_date));
  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.change_subscription_day(uuid, text, date) to authenticated;

create or replace function public.cancel_storefront_subscription(p_id uuid) returns jsonb
language plpgsql security definer set search_path to 'public' as $$
declare s storefront_subscriptions;
begin
  select * into s from storefront_subscriptions where id = p_id for update;
  if s.id is null or not is_business_operational(s.business_id) then raise exception 'forbidden'; end if;
  update storefront_subscriptions set status = 'cancelled' where id = p_id;
  update storefront_subscription_days set status = 'skipped', updated_at = now() where subscription_id = p_id and status = 'scheduled';
  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.cancel_storefront_subscription(uuid) to authenticated;

do $$ begin
  perform cron.unschedule('storefront-subscriptions') where exists (select 1 from cron.job where jobname = 'storefront-subscriptions');
  perform cron.schedule('storefront-subscriptions', '5 16 * * *', 'select public.storefront_subscription_tick()');
end $$;
CREATE OR REPLACE FUNCTION public.get_storefront(p_business_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare page public_order_pages; base text; candidate text; n int := 0;
begin
  if not is_business_operational(p_business_id) then raise exception 'forbidden'; end if;
  select * into page from public_order_pages where business_id = p_business_id;
  if page.id is null then
    select _normalize_storefront_slug(name) into base from businesses where id = p_business_id;
    if base is null or length(base) < 3 then base := 'store'; end if;
    base := regexp_replace(base, '-+$', '');
    candidate := base;
    while not _storefront_slug_available(candidate, p_business_id) loop
      n := n + 1;
      candidate := regexp_replace(left(base, 30 - length(n::text) - 1), '-+$', '') || '-' || n;
    end loop;
    insert into public_order_pages(business_id, slug, access_token_hash, enabled, updated_by)
      values (p_business_id, candidate, encode(digest(gen_random_bytes(32), 'sha256'), 'hex'), false, auth.uid())
      on conflict (business_id) do nothing
      returning * into page;
    if page.id is null then
      select * into page from public_order_pages where business_id = p_business_id;
    else
      insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
        values (p_business_id, 'storefront.created', auth.uid(), 'vendor', jsonb_build_object('slug', page.slug));
    end if;
  end if;
  return jsonb_build_object('slug', page.slug, 'published', page.enabled,
    'published_at', page.published_at, 'template_key', page.template_key, 'theme', page.theme,
    'delivery_fee', page.delivery_fee, 'delivery_days', to_jsonb(page.delivery_days),
    'delivery_shifts', page.delivery_shifts, 'package_weeks', to_jsonb(page.package_weeks));
end $function$;
drop function if exists public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text);
CREATE OR REPLACE FUNCTION public.submit_storefront_order(p_slug text, p_items jsonb, p_customer_name text, p_customer_phone text, p_delivery_address text, p_delivery_notes text DEFAULT ''::text, p_idempotency_key uuid DEFAULT NULL::uuid, p_latitude double precision DEFAULT NULL::double precision, p_longitude double precision DEFAULT NULL::double precision, p_location_accuracy_m numeric DEFAULT NULL::numeric, p_location_source text DEFAULT NULL::text, p_plan jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  page public.public_order_pages; allowed boolean; existing public.orders; digits text; t text; res jsonb;
begin
  begin
    allowed := check_rate_limit(_public_caller_key('submit_storefront_order'), 'submit_storefront_order', 60, 5);
  exception when others then allowed := false;  -- fail closed
  end;
  if not allowed then raise exception 'rate limited'; end if;
  -- From here every refusal is RETURNED (not raised) so the attempt stays counted.
  page := _resolve_storefront(lower(btrim(coalesce(p_slug, ''))));
  if page.id is null then
    perform record_invalid_lookup_telemetry('submit_storefront_order');
    return jsonb_build_object('error', 'invalid or unavailable storefront');
  end if;
  begin
    allowed := check_rate_limit(encode(digest('store:' || page.id::text, 'sha256'), 'hex'), 'submit_storefront_order_store', 60, 120);
  exception when others then allowed := false;
  end;
  if not allowed then return jsonb_build_object('error', 'rate limited'); end if;
  if p_idempotency_key is null then return jsonb_build_object('error', 'invalid idempotency key'); end if;

  -- Replay of an order already created with this key (same store, last 24 h):
  -- the same reference plus a fresh tracking token for that order only.
  select * into existing from public.orders
   where submission_idempotency_key = p_idempotency_key and business_id = page.business_id;
  if existing.id is not null then
    if existing.created_at < now() - interval '24 hours' then
      return jsonb_build_object('order_reference', existing.public_ref, 'tracking_token', null, 'replay', true);
    end if;
    -- One token per order (unique): rotate it like rotate_tracking_token, so
    -- the token the customer now holds is the working one.
    t := encode(gen_random_bytes(32), 'hex');
    update public.tracking_tokens
       set token_hash = encode(digest(t, 'sha256'), 'hex'),
           expires_at = case when existing.delivery_status = 'delivered' then now() + interval '48 hours' else null end,
           revoked_at = null
     where order_id = existing.id;
    if not found then
      insert into public.tracking_tokens(order_id, token_hash) values (existing.id, encode(digest(t, 'sha256'), 'hex'));
    end if;
    return jsonb_build_object('order_reference', existing.public_ref, 'tracking_token', t, 'replay', true);
  end if;

  if exists (select 1 from business_hours h where h.business_id = page.business_id)
     and not business_open_now(page.business_id) then
    return jsonb_build_object('error', 'store closed', 'next_open', _business_next_open(page.business_id));
  end if;

  digits := regexp_replace(coalesce(p_customer_phone, ''), '[\s().-]', '', 'g');
  if digits !~ '^\+?[0-9]{7,15}$' then
    return jsonb_build_object('error', 'invalid customer phone');
  end if;

  -- Delivery pin (Founder 2026-10-08): both or neither; Malaysia bounds only.
  if (p_latitude is null) <> (p_longitude is null)
     or (p_latitude is not null and not (p_latitude between 0.5 and 7.6 and p_longitude between 99.5 and 119.5)) then
    return jsonb_build_object('error', 'invalid delivery pin');
  end if;
  if p_location_source is not null and p_location_source not in ('gps', 'pin_adjusted', 'map') then
    return jsonb_build_object('error', 'invalid delivery pin');
  end if;

  -- Coverage (Founder 2026-10-17): a store with a radius does not take orders
  -- pinned outside it; its drivers cannot reach there.
  if _storefront_covers(page, p_latitude, p_longitude) is false then
    return jsonb_build_object('error', 'outside coverage');
  end if;
  if p_latitude is null and exists (select 1 from businesses b where b.id = page.business_id and b.service_coverage_radius_km is not null) then
    return jsonb_build_object('error', 'invalid delivery pin');
  end if;

  begin
    res := _create_public_order(page, p_items, p_customer_name, p_customer_phone,
                                p_delivery_address, p_delivery_notes, p_idempotency_key);
  exception when others then
    return jsonb_build_object('error', sqlerrm);
  end;

  -- Subscription package (Founder 2026-10-17): the first delivery is this
  -- order; the rest are created on their day by storefront_subscription_tick.
  if p_plan is not null and coalesce(p_plan->>'weeks', 'once') <> 'once' and coalesce((res->>'replay')::boolean, false) is false then
    perform _start_storefront_subscription(page, p_plan, p_items, p_customer_name, p_customer_phone,
      p_delivery_address, p_delivery_notes, p_latitude, p_longitude, p_idempotency_key);
  end if;

  if p_latitude is not null and res ? 'order_reference' and p_idempotency_key is not null then
    update public.orders
       set latitude = round(p_latitude::numeric, 6), longitude = round(p_longitude::numeric, 6),
           location_accuracy_m = case when p_location_accuracy_m between 0 and 100000 then round(p_location_accuracy_m) end,
           location_source = coalesce(p_location_source, 'map'),
           location_status = 'resolved', location_provider = 'customer_pin',
           location_resolved_at = now(), location_error = null
     where business_id = page.business_id and submission_idempotency_key = p_idempotency_key;
  end if;
  return res;
end $function$;
grant execute on function public.submit_storefront_order(text, jsonb, text, text, text, text, uuid, double precision, double precision, numeric, text, jsonb) to anon, authenticated;
