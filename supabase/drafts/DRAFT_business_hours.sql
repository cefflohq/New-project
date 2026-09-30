-- DRAFT — NOT APPLIED. Founder approval required before staging apply.
-- CEFFLO Business Hours V1 (Founder, 2026-10-01).
--
-- One row per business per weekday (ISO: 1 = Monday .. 7 = Sunday).
-- A day is either closed, or open from opens_at to closes_at in the
-- BUSINESS's own timezone (businesses.timezone, e.g. Asia/Kuala_Lumpur).
-- Times are wall-clock `time` values, never UTC instants, so daylight/
-- offset changes never shift a shop's hours. V1 has one interval per day
-- and no holiday/exception system (deliberately out of scope).
--
-- Overnight hours (e.g. 18:00-02:00) are allowed: closes_at < opens_at
-- means "closes the next day". 24h = opens_at = closes_at = 00:00.
--
-- Reads: every member (Vendor apps) and, through the public storefront
-- function, customers (open/closed display). Writes: Owner only, through
-- one RPC that replaces the whole week atomically.

create table public.business_hours (
  business_id uuid not null references public.businesses(id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  is_open boolean not null default false,
  opens_at time,
  closes_at time,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  primary key (business_id, weekday),
  -- Closed days carry no times; open days carry both.
  constraint business_hours_times_match_state check (
    (is_open and opens_at is not null and closes_at is not null)
    or (not is_open and opens_at is null and closes_at is null)
  )
);
alter table public.business_hours enable row level security;

create policy business_hours_member_read on public.business_hours
  for select to authenticated
  using (is_business_member(business_id));
-- No insert/update/delete policies: writes only via set_business_hours.

-- Replace the whole week. p_days: [{weekday, is_open, opens_at, closes_at}]
-- exactly 7 entries, weekdays 1..7 each once. Owner only.
create or replace function public.set_business_hours(p_business_id uuid, p_days jsonb)
returns setof public.business_hours
language plpgsql security definer set search_path to 'public' as $$
declare d jsonb; seen int[] := '{}'; wd int;
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  if jsonb_typeof(p_days) <> 'array' or jsonb_array_length(p_days) <> 7 then
    raise exception 'exactly 7 days required';
  end if;
  for d in select * from jsonb_array_elements(p_days) loop
    wd := (d->>'weekday')::int;
    if wd is null or wd not between 1 and 7 or wd = any(seen) then
      raise exception 'invalid weekday';
    end if;
    seen := seen || wd;
  end loop;

  delete from business_hours where business_id = p_business_id;
  insert into business_hours(business_id, weekday, is_open, opens_at, closes_at, updated_by)
  select p_business_id,
         (x->>'weekday')::smallint,
         coalesce((x->>'is_open')::boolean, false),
         case when (x->>'is_open')::boolean then (x->>'opens_at')::time end,
         case when (x->>'is_open')::boolean then (x->>'closes_at')::time end,
         auth.uid()
    from jsonb_array_elements(p_days) x;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'business.hours_updated', auth.uid(), 'vendor', '{}'::jsonb);

  return query select * from business_hours where business_id = p_business_id order by weekday;
end $$;

-- "Open right now?" in the business's own timezone. Used by the future
-- storefront (and any Vendor screen) so every surface agrees.
create or replace function public.business_open_now(p_business_id uuid)
returns boolean language sql stable security definer set search_path to 'public' as $$
  with local as (
    select (now() at time zone coalesce(b.timezone, 'Asia/Kuala_Lumpur')) as ts
      from businesses b where b.id = p_business_id
  ), today as (
    select h.* , l.ts from business_hours h, local l
     where h.business_id = p_business_id
       and h.weekday = extract(isodow from l.ts)
  ), yesterday as (
    select h.*, l.ts from business_hours h, local l
     where h.business_id = p_business_id
       and h.weekday = case when extract(isodow from l.ts) = 1 then 7 else extract(isodow from l.ts) - 1 end
  )
  select coalesce(
    -- today's interval (same-day, overnight start, or 24h)
    (select t.is_open and (
        (t.opens_at = t.closes_at)
        or (t.opens_at < t.closes_at and t.ts::time >= t.opens_at and t.ts::time < t.closes_at)
        or (t.opens_at > t.closes_at and t.ts::time >= t.opens_at)
     ) from today t), false)
  or coalesce(
    -- yesterday's overnight interval spilling past midnight
    (select y.is_open and y.opens_at > y.closes_at and y.ts::time < y.closes_at from yesterday y), false)
$$;

revoke all on function public.set_business_hours(uuid, jsonb) from public, anon;
grant execute on function public.set_business_hours(uuid, jsonb) to authenticated;
revoke all on function public.business_open_now(uuid) from public, anon;
grant execute on function public.business_open_now(uuid) to authenticated;
-- The storefront exposes open/closed through its own public function
-- (see DRAFT_storefront_v1.sql), never this table directly to anon.
