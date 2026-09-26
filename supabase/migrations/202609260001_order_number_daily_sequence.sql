-- D-64: human-facing order number "#CF-001", per business, reset every
-- business-local calendar day (businesses.timezone). Display/operational only:
-- orders.id stays the identity, public_ref is unchanged, and tracking keeps
-- its token. Uniqueness is (business_id, order_date, order_seq).

alter table public.orders
  add column order_date date,
  add column order_seq integer;

-- Deterministic staging/historical backfill: per business and business-local
-- day of created_at, numbered by (created_at, id).
with numbered as (
  select o.id,
         (o.created_at at time zone b.timezone)::date as d,
         row_number() over (
           partition by o.business_id, (o.created_at at time zone b.timezone)::date
           order by o.created_at, o.id) as n
  from public.orders o
  join public.businesses b on b.id = o.business_id
)
update public.orders o set order_date = n.d, order_seq = n.n
from numbered n where n.id = o.id;

alter table public.orders
  alter column order_date set not null,
  alter column order_seq set not null,
  add constraint orders_order_seq_positive check (order_seq > 0),
  add constraint orders_business_day_seq_key unique (business_id, order_date, order_seq),
  add column order_number text generated always as (
    '#CF-' || case when order_seq < 1000 then lpad(order_seq::text, 3, '0')
                   else order_seq::text end
  ) stored;

-- Assigned on insert under a per-business-day transaction lock, so
-- concurrent inserts for the same business and day are serialized; the
-- unique constraint is the backstop. Never changes after insert.
create function public.assign_order_number() returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  tz text;
begin
  if tg_op = 'UPDATE' then
    new.order_date := old.order_date;
    new.order_seq := old.order_seq;
    return new;
  end if;
  select timezone into tz from businesses where id = new.business_id;
  new.order_date := (coalesce(new.created_at, now()) at time zone coalesce(tz, 'Asia/Kuala_Lumpur'))::date;
  perform pg_advisory_xact_lock(hashtextextended(new.business_id::text || ':' || new.order_date::text, 0));
  select coalesce(max(order_seq), 0) + 1 into new.order_seq
  from orders where business_id = new.business_id and order_date = new.order_date;
  return new;
end;
$$;

revoke all on function public.assign_order_number() from public, anon, authenticated;

create trigger orders_assign_order_number
before insert or update of order_date, order_seq on public.orders
for each row execute function public.assign_order_number();

-- public_tracking: the only change from 202609030008 is the additive
-- 'order_number' key (display). Access is still by token only.
create or replace function public.public_tracking(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  key text;
  allowed boolean;
  result jsonb;
  eta_result jsonb;
  order_id_lookup uuid;
begin
  key := encode(digest(p_token, 'sha256'), 'hex');

  begin
    allowed := check_rate_limit(key, 'public_tracking', 60, 10);
  exception when others then
    allowed := true;
  end;

  if not allowed then
    raise exception 'rate limited';
  end if;

  select t.order_id into order_id_lookup
  from tracking_tokens t
  where t.token_hash = key
    and t.revoked_at is null
    and (t.expires_at is null or t.expires_at > now());

  if order_id_lookup is not null then
    eta_result := compute_order_eta(order_id_lookup);
  end if;

  select jsonb_build_object(
    'order_id', o.public_ref,
    'order_number', o.order_number,
    'store_name', b.name,
    'status', o.delivery_status,
    'eta', eta_result,
    'rider_name', r.name,
    'completed_at', o.completed_at,
    'pod_available', (o.delivery_status = 'delivered' and s.pod_storage_path is not null),
    'rating_submitted', rt.id is not null
  ) into result
  from tracking_tokens t
  join orders o on o.id = t.order_id
  join businesses b on b.id = o.business_id
  left join riders r on r.id = o.assigned_rider_id
  join delivery_stops s on s.order_id = o.id
  left join ratings rt on rt.order_id = o.id
  where t.token_hash = key
    and t.revoked_at is null
    and (t.expires_at is null or t.expires_at > now());

  if result is null then
    perform record_invalid_lookup_telemetry('public_tracking');
  end if;

  return result;
end;
$$;

-- list_plannable_orders: additive order_number column (display) for Vendor planning.
drop function public.list_plannable_orders(uuid);
create function public.list_plannable_orders(p_business_id uuid) returns table(
  order_id uuid,
  public_ref text,
  customer_name text,
  delivery_address text,
  latitude double precision,
  longitude double precision,
  location_status public.order_location_status,
  coverage_status text,
  zone_id uuid,
  approved_at timestamptz,
  created_at timestamptz,
  order_number text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  return query
    select o.id, o.public_ref, o.customer_name, o.delivery_address, o.latitude, o.longitude,
           o.location_status, order_coverage_status(o.id), o.zone_id, o.approved_at, o.created_at,
           o.order_number
    from public.orders o
    where o.business_id = p_business_id
      and o.delivery_status = 'created'
      and o.approved_at is not null
      and o.assigned_rider_id is null
    order by o.created_at asc;
end;
$$;

revoke all on function public.list_plannable_orders(uuid) from public, anon;
grant execute on function public.list_plannable_orders(uuid) to authenticated;
