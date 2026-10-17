-- Invited drivers upload their licence and vehicle before a business can
-- approve them (Founder 2026-10-16, option B).
create or replace function public.approve_pending_rider(p_rider_id uuid)
 returns riders language plpgsql security definer set search_path to 'public'
as $function$
declare
  r riders;
begin
  select * into r from riders where id = p_rider_id for update;
  if r.id is null or not is_business_operational(r.business_id) then
    raise exception 'forbidden';
  end if;
  if r.status <> 'pending' then
    raise exception 'rider not pending';
  end if;
  if r.auth_user_id is not null and (
       not exists (select 1 from driver_licences l where l.user_id = r.auth_user_id)
       or not exists (select 1 from driver_marketplace_verifications v
                       where v.user_id = r.auth_user_id and v.vehicle_photo_path is not null)) then
    raise exception 'driver documents not submitted yet';
  end if;
  update riders set status = 'active', updated_at = now() where id = r.id returning * into r;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (r.business_id, 'rider.approved', auth.uid(), 'vendor', jsonb_build_object('rider_id', r.id));
  return r;
end;
$function$;
