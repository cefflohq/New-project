-- Subscription, pre-payment (Founder 2026-10-06; staging first).
--
-- Authority for the plan catalogue: the Founder-locked Malaysia price book
-- (10_PRICING.md as locked on 2026-09-28, kept in tag
-- backup/2026-10-03/claude/public-website, commit 50c6856) and the
-- Founder-approved Public Website (website/index.html, 1f522f6), which
-- publishes exactly these plans, prices, allowances and caps:
--   FREE RM0 150 / GROW RM99 500 / OPERATE RM199 1,500 (most popular) /
--   SCALE RM499 5,000 / ENTERPRISE custom; caps 3 drivers 2 zones 1 user,
--   10/5/3, unlimited/unlimited/10, unlimited/unlimited/25.
-- "The FREE plan needs no payment details" and "Only completed deliveries
-- count" (published) -> every business is on FREE unless FOUNDR (later: a
-- verified payment) sets another plan. Annual pricing, overage and cap
-- ENFORCEMENT are not locked and are not implemented here (caps are shown,
-- not enforced). No payment, checkout, invoice or transaction is created.
--
-- 1. subscription_plans: the public price book (read-only for clients).
-- 2. business_subscriptions: plan_key must be a real plan; default FREE /
--    active; every existing business backfilled to FREE; new businesses get
--    FREE on creation.
-- 3. admin_set_subscription (FOUNDR): unchanged authority, now validates the
--    plan key.
-- 4. my_subscription(business): Owner-only read of plan + status + usage
--    for the current cycle (calendar month in businesses.timezone until a
--    payment provider defines paid billing periods).
-- 5. request_plan_change(business, plan): Owner-only; validates, then stops
--    at the PAYMENT BOUNDARY (returns payment_required, payment_enabled
--    false). Writes nothing. The payment provider later plugs in here.
-- Grants: plans readable by anon + authenticated (published prices); RPCs
-- authenticated only. RLS: unchanged for business_subscriptions (Owner read,
-- platform admin read; no client writes).
-- Rollback: drop the two RPCs, the trigger + function, the FK and the
-- table; restore defaults ('trial','trial') and admin_set_subscription
-- from 202608300002-era definition. Backfilled FREE rows may be deleted.

create table if not exists public.subscription_plans (
  key text primary key check (key in ('free', 'grow', 'operate', 'scale', 'enterprise')),
  name text not null,
  monthly_price_myr numeric(10,2),          -- null = custom (Enterprise)
  delivery_allowance integer,               -- completed deliveries / cycle; null = custom
  driver_cap integer,                       -- null = unlimited (shown, not enforced)
  zone_cap integer,                         -- null = unlimited (shown, not enforced)
  team_user_cap integer,                    -- null = custom
  most_popular boolean not null default false,
  self_serve boolean not null default true, -- false = contact sales (Enterprise)
  sort smallint not null
);

insert into public.subscription_plans
  (key, name, monthly_price_myr, delivery_allowance, driver_cap, zone_cap, team_user_cap, most_popular, self_serve, sort)
values
  ('free',       'Free',       0,    150,  3,    2,    1,    false, true,  1),
  ('grow',       'Grow',       99,   500,  10,   5,    3,    false, true,  2),
  ('operate',    'Operate',    199,  1500, null, null, 10,   true,  true,  3),
  ('scale',      'Scale',      499,  5000, null, null, 25,   false, true,  4),
  ('enterprise', 'Enterprise', null, null, null, null, null, false, false, 5)
on conflict (key) do update set
  name = excluded.name, monthly_price_myr = excluded.monthly_price_myr,
  delivery_allowance = excluded.delivery_allowance, driver_cap = excluded.driver_cap,
  zone_cap = excluded.zone_cap, team_user_cap = excluded.team_user_cap,
  most_popular = excluded.most_popular, self_serve = excluded.self_serve, sort = excluded.sort;

alter table public.subscription_plans enable row level security;
drop policy if exists subscription_plans_public_read on public.subscription_plans;
create policy subscription_plans_public_read on public.subscription_plans
  for select to anon, authenticated using (true);
revoke insert, update, delete, truncate on public.subscription_plans from anon, authenticated;
grant select on public.subscription_plans to anon, authenticated;

-- business_subscriptions: real plans only; FREE is the default.
update public.business_subscriptions set plan_key = 'free'
  where plan_key not in (select key from public.subscription_plans);
alter table public.business_subscriptions alter column plan_key set default 'free';
alter table public.business_subscriptions alter column status set default 'active';
alter table public.business_subscriptions
  drop constraint if exists business_subscriptions_plan_key_fkey;
alter table public.business_subscriptions
  add constraint business_subscriptions_plan_key_fkey
  foreign key (plan_key) references public.subscription_plans(key);

insert into public.business_subscriptions (business_id, plan_key, status)
select b.id, 'free', 'active' from public.businesses b
where not exists (select 1 from public.business_subscriptions s where s.business_id = b.id);

create or replace function public._business_starts_on_free()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.business_subscriptions (business_id, plan_key, status)
  values (new.id, 'free', 'active')
  on conflict (business_id) do nothing;
  return new;
end $$;
revoke all on function public._business_starts_on_free() from public, anon, authenticated;

drop trigger if exists businesses_start_on_free on public.businesses;
create trigger businesses_start_on_free
  after insert on public.businesses
  for each row execute function public._business_starts_on_free();

-- FOUNDR authority unchanged; the plan must exist.
create or replace function public.admin_set_subscription(p_business_id uuid, p_plan_key text, p_status text, p_mrr_cents integer default null::integer, p_trial_ends_at timestamp with time zone default null::timestamp with time zone)
returns public.business_subscriptions
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  s public.business_subscriptions;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  if p_status not in ('trial', 'active', 'past_due', 'suspended', 'cancelled') then
    raise exception 'invalid status';
  end if;
  if not exists (select 1 from public.subscription_plans where key = p_plan_key) then
    raise exception 'invalid plan';
  end if;

  insert into public.business_subscriptions (business_id, plan_key, status, mrr_cents, trial_ends_at, updated_by, updated_at)
  values (p_business_id, p_plan_key, p_status, p_mrr_cents, p_trial_ends_at, auth.uid(), now())
  on conflict (business_id) do update set
    plan_key = excluded.plan_key, status = excluded.status, mrr_cents = excluded.mrr_cents,
    trial_ends_at = excluded.trial_ends_at, updated_by = excluded.updated_by, updated_at = excluded.updated_at
  returning * into s;

  perform public.log_admin_action('set_subscription', 'business', p_business_id::text, null,
    jsonb_build_object('plan_key', p_plan_key, 'status', p_status, 'mrr_cents', p_mrr_cents));
  return s;
end;
$function$;

-- Owner: current plan, status and this cycle's usage.
create or replace function public.my_subscription(p_business_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  s public.business_subscriptions;
  p public.subscription_plans;
  tz text;
  cycle_start date;
  cycle_end date;
  used int;
begin
  if not public.is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;
  select * into s from public.business_subscriptions where business_id = p_business_id;
  select * into p from public.subscription_plans where key = coalesce(s.plan_key, 'free');
  select coalesce(timezone, 'Asia/Kuala_Lumpur') into tz from public.businesses where id = p_business_id;
  cycle_start := date_trunc('month', now() at time zone tz)::date;
  cycle_end := (cycle_start + interval '1 month' - interval '1 day')::date;
  -- Only completed deliveries count (published pricing rule).
  select count(*) into used from public.orders o
   where o.business_id = p_business_id and o.delivery_status = 'delivered'
     and o.completed_at is not null
     and (o.completed_at at time zone tz)::date between cycle_start and cycle_end;
  return jsonb_build_object(
    'plan_key', p.key,
    'status', coalesce(s.status, 'active'),
    'has_record', s.business_id is not null,
    'trial_ends_at', s.trial_ends_at,
    'cycle_start', cycle_start,
    'cycle_end', cycle_end,
    'deliveries_used', used,
    'delivery_allowance', p.delivery_allowance,
    'over_allowance', p.delivery_allowance is not null and used > p.delivery_allowance,
    'drivers_active', (select count(*) from public.riders where business_id = p_business_id and status = 'active'),
    'zones_active', (select count(*) from public.zones where business_id = p_business_id and status = 'active'),
    'team_users', (select count(*) from public.business_members where business_id = p_business_id and status = 'active'),
    'payment_enabled', false
  );
end $$;
revoke all on function public.my_subscription(uuid) from public, anon;
grant execute on function public.my_subscription(uuid) to authenticated;

-- Owner: change-plan request. Stops at the payment boundary; writes nothing.
create or replace function public.request_plan_change(p_business_id uuid, p_plan_key text)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  cur text;
  p public.subscription_plans;
begin
  if not public.is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;
  select * into p from public.subscription_plans where key = p_plan_key;
  if p.key is null then
    raise exception 'invalid plan';
  end if;
  select coalesce((select plan_key from public.business_subscriptions where business_id = p_business_id), 'free') into cur;
  if p.key = cur then
    return jsonb_build_object('status', 'current_plan', 'plan_key', p.key);
  end if;
  if not p.self_serve then
    return jsonb_build_object('status', 'contact_sales', 'plan_key', p.key);
  end if;
  if coalesce(p.monthly_price_myr, 0) = 0 then
    -- Leaving a paid plan is a cancellation lifecycle handled with the
    -- payment provider / FOUNDR, never a silent client switch.
    return jsonb_build_object('status', 'contact_support', 'plan_key', p.key);
  end if;
  -- PAYMENT BOUNDARY: a paid plan becomes active only after a verified
  -- payment (server-side, provider webhook) -- not enabled yet.
  return jsonb_build_object(
    'status', 'payment_required',
    'plan_key', p.key,
    'amount_myr', p.monthly_price_myr,
    'payment_enabled', false
  );
end $$;
revoke all on function public.request_plan_change(uuid, text) from public, anon;
grant execute on function public.request_plan_change(uuid, text) to authenticated;
