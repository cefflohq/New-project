-- Pickup Checklist ticks live on the Driver's account, not the phone
-- (Founder 2026-10-14). A tick survives an app restart or a phone switch
-- until Confirm Pickup. Only the rider assigned to the run reads or writes
-- its ticks, and only for orders in that run.

create table if not exists public.rider_pickup_ticks (
  delivery_session_id uuid not null references public.delivery_sessions(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  rider_id uuid not null references public.riders(id) on delete cascade,
  ticked_at timestamptz not null default now(),
  primary key (delivery_session_id, order_id)
);

alter table public.rider_pickup_ticks enable row level security;
-- No policies: access is through the functions below only.
revoke all on public.rider_pickup_ticks from public, anon, authenticated;

create or replace function public.set_pickup_tick(
  p_rider_id uuid,
  p_delivery_session_id uuid,
  p_order_id uuid,
  p_ticked boolean
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_current_rider(p_rider_id) then raise exception 'invalid rider context'; end if;
  if not exists (select 1 from rider_assignments a
                  where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id) then
    raise exception 'no assignments in this run';
  end if;
  if not exists (select 1 from orders o
                  where o.id = p_order_id and o.delivery_session_id = p_delivery_session_id) then
    raise exception 'order not in this run';
  end if;
  if coalesce(p_ticked, false) then
    insert into rider_pickup_ticks(delivery_session_id, order_id, rider_id)
      values (p_delivery_session_id, p_order_id, p_rider_id)
      on conflict (delivery_session_id, order_id)
      do update set rider_id = excluded.rider_id, ticked_at = now();
  else
    delete from rider_pickup_ticks
      where delivery_session_id = p_delivery_session_id and order_id = p_order_id;
  end if;
end $$;

create or replace function public.my_pickup_ticks(
  p_rider_id uuid,
  p_delivery_session_id uuid
) returns setof uuid
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_current_rider(p_rider_id) then raise exception 'invalid rider context'; end if;
  if not exists (select 1 from rider_assignments a
                  where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id) then
    raise exception 'no assignments in this run';
  end if;
  return query select t.order_id from rider_pickup_ticks t
    where t.delivery_session_id = p_delivery_session_id;
end $$;

revoke all on function public.set_pickup_tick(uuid, uuid, uuid, boolean) from public, anon;
grant execute on function public.set_pickup_tick(uuid, uuid, uuid, boolean) to authenticated;
revoke all on function public.my_pickup_ticks(uuid, uuid) from public, anon;
grant execute on function public.my_pickup_ticks(uuid, uuid) to authenticated;
