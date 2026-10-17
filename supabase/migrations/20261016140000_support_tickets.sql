-- Driver support tickets (Founder 2026-10-16): a customer / delivery /
-- business issue goes to the driver's vendor (in-app notification to the
-- business owner and operators); an app, account or other issue goes to
-- the Cefflo founder team (kept here, read in the dashboard).
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  rider_id uuid references public.riders(id) on delete set null,
  business_id uuid references public.businesses(id) on delete cascade,
  category text not null check (category in
    ('delivery_run','vendor_business','cefflo_app','account_documents','other')),
  audience text not null check (audience in ('vendor','cefflo')),
  description text not null check (length(trim(description)) between 1 and 4000),
  status text not null default 'open' check (status in ('open','resolved')),
  created_at timestamptz not null default now()
);
create index if not exists support_tickets_business_idx on public.support_tickets(business_id, created_at desc);
alter table public.support_tickets enable row level security;
create policy support_tickets_own on public.support_tickets
  for select using (auth_user_id = auth.uid());
create policy support_tickets_vendor on public.support_tickets
  for select using (audience = 'vendor' and is_business_member(business_id));

create or replace function public.submit_support_ticket(
  p_category text, p_description text, p_rider_id uuid default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_rider riders;
  v_audience text := case when p_category in ('delivery_run','vendor_business') then 'vendor' else 'cefflo' end;
  m record;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if p_rider_id is not null then
    select * into v_rider from riders where id = p_rider_id and auth_user_id = auth.uid();
    if v_rider.id is null then raise exception 'forbidden'; end if;
  end if;
  -- A vendor ticket needs the business the driver works for.
  if v_audience = 'vendor' and v_rider.id is null then v_audience := 'cefflo'; end if;
  insert into support_tickets (auth_user_id, rider_id, business_id, category, audience, description)
  values (auth.uid(), v_rider.id, v_rider.business_id, p_category, v_audience, trim(p_description))
  returning id into v_id;
  if v_audience = 'vendor' then
    for m in select user_id from business_members
              where business_id = v_rider.business_id and coalesce(status,'active') = 'active' loop
      perform notify_user(m.user_id, 'vendor', v_rider.business_id, 'support.ticket', 'operational',
        'normal', 'Driver support: ' || v_rider.name, left(trim(p_description), 200),
        jsonb_build_object('screen','rider','id', v_rider.id), jsonb_build_object('ticket_id', v_id, 'name', v_rider.name),
        'support:' || v_id);
    end loop;
  end if;
  return v_id;
end $$;
revoke all on function public.submit_support_ticket(text, text, uuid) from public, anon;
grant execute on function public.submit_support_ticket(text, text, uuid) to authenticated;
