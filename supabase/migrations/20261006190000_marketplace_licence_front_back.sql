-- Marketplace Verification V1 — licence FRONT + BACK (Founder 2026-10-06).
-- Both are live camera captures (enforced in the Driver app) and both are
-- required. They belong exclusively to Cefflo Marketplace Verification:
-- no business access of any kind (no Owner model is restored). OCR runs on
-- both sides and the extracted fields are combined before the SQL rules.
-- Rollback: re-apply submit_driver_licence(text, text) from 20261006180000
-- and rename front_path back to licence_path / drop back_path.

alter table public.driver_licences rename column licence_path to front_path;
alter table public.driver_licences add column if not exists back_path text;

revoke select on public.driver_licences from authenticated;
grant select (user_id, ic_last4, front_path, back_path, submitted_at) on public.driver_licences to authenticated; -- platform admin only via RLS

drop function if exists public.submit_driver_licence(text, text);
create or replace function public.submit_driver_licence(p_ic_number text, p_front_path text, p_back_path text)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_norm text := _ic_normalize(p_ic_number);
  v_hash text;
  v_mine driver_licences;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if v_norm !~ '^[0-9]{12}$'
     or substr(v_norm, 3, 2)::int not between 1 and 12
     or substr(v_norm, 5, 2)::int not between 1 and 31 then
    raise exception 'invalid IC number';
  end if;
  if p_front_path is null or p_back_path is null or p_front_path = p_back_path
     or split_part(p_front_path, '/', 1) <> auth.uid()::text
     or split_part(p_back_path, '/', 1) <> auth.uid()::text
     or (select count(*) from storage.objects o where o.bucket_id = 'cefflo-driver-documents'
           and o.name in (p_front_path, p_back_path)) <> 2 then
    raise exception 'licence front and back photos required';
  end if;
  v_hash := _ic_hash(v_norm);
  if exists (select 1 from driver_licences where ic_hash = v_hash and user_id <> auth.uid()) then
    raise exception 'IC already registered to another account';
  end if;
  select * into v_mine from driver_licences where user_id = auth.uid() for update;
  if v_mine.user_id is not null and v_mine.ic_hash <> v_hash
     and exists (select 1 from driver_marketplace_verifications where user_id = auth.uid() and status = 'verified') then
    raise exception 'a verified identity cannot be replaced; contact Cefflo support';
  end if;
  if exists (select 1 from driver_marketplace_verifications where user_id = auth.uid() and status in ('verified', 'rejected')) then
    raise exception 'verification already decided';
  end if;
  insert into driver_licences(user_id, ic_hash, ic_last4, front_path, back_path, submitted_at)
    values (auth.uid(), v_hash, right(v_norm, 4), p_front_path, p_back_path, now())
  on conflict (user_id) do update
    set ic_hash = excluded.ic_hash, ic_last4 = excluded.ic_last4,
        front_path = excluded.front_path, back_path = excluded.back_path, submitted_at = now();
  insert into driver_marketplace_verifications(user_id, status, submitted_at)
    values (auth.uid(), 'pending', now())
  on conflict (user_id) do update
    set status = 'pending', licence_result = null, retake = null, submitted_at = now(), updated_at = now();
  perform _marketplace_decide(auth.uid());
  return my_marketplace_verification();
end $$;
revoke all on function public.submit_driver_licence(text, text, text) from public, anon;
grant execute on function public.submit_driver_licence(text, text, text) to authenticated;

/* Decision rules (front + back combined by the Edge Function: text_found
   is false when EITHER side has no usable text -> retake). Confidence threshold 0.85. Retake after 3 failed
   screenings becomes needs_review ('repeated_retakes'). */
create or replace function public._marketplace_decide(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v driver_marketplace_verifications;
  l driver_licences;
  lr jsonb; pr jsonb;
  v_reasons text[] := '{}';
  v_retake text;
  v_lic_ok boolean := false; v_plate_ok boolean := false;
  v_name text; v_classes text[]; v_expiry date; v_declared text; v_best jsonb; v_p text;
  v_status text;
  v_missing boolean := false;
begin
  select * into v from driver_marketplace_verifications where user_id = p_user for update;
  select * into l from driver_licences where user_id = p_user;
  if v.user_id is null or v.status in ('verified', 'rejected') then return; end if;
  lr := v.licence_result; pr := v.plate_result;

  -- licence
  if l.user_id is null or l.front_path is null or l.back_path is null then
    v_missing := true; -- both licence sides required
  elsif lr is null then
    null; -- not screened yet
  elsif coalesce((lr ->> 'text_found')::boolean, false) is false or nullif(lr ->> 'ic', '') is null then
    v_retake := 'licence'; v_reasons := array_append(v_reasons, 'licence_unreadable');
  elsif _ic_hash(lr ->> 'ic') <> l.ic_hash then
    v_reasons := array_append(v_reasons, 'ic_mismatch');
  else
    v_classes := array(select upper(jsonb_array_elements_text(coalesce(lr -> 'classes', '[]'))));
    v_expiry := nullif(lr ->> 'expiry', '')::date;
    if cardinality(v_classes) = 0 or v_expiry is null then
      v_retake := 'licence'; v_reasons := array_append(v_reasons, 'licence_fields_missing');
    else
      select coalesce(nullif(btrim(raw_user_meta_data -> 'driver_registration' ->> 'full_name'), ''),
                      (select name from riders where auth_user_id = p_user order by updated_at desc limit 1))
        into v_name from auth.users where id = p_user;
      if coalesce((lr ->> 'confidence')::numeric, 0) < 0.85 then v_reasons := array_append(v_reasons, 'low_confidence'); end if;
      if nullif(lr ->> 'name', '') is null or v_name is null
         or not (_name_tokens(v_name) <@ _name_tokens(lr ->> 'name') or _name_tokens(lr ->> 'name') <@ _name_tokens(v_name))
         or cardinality(_name_tokens(v_name)) = 0 then
        v_reasons := array_append(v_reasons, 'name_mismatch');
      end if;
      if v_expiry < current_date then v_reasons := array_append(v_reasons, 'licence_expired'); end if;
      if v_expiry > current_date + interval '15 years' then v_reasons := array_append(v_reasons, 'expiry_suspicious'); end if;
      if v.vehicle_type is not null and not (v_classes && case v.vehicle_type
           when 'motorcycle' then array['B', 'B1', 'B2', 'B FULL']
           else array['D', 'DA', 'E', 'E1', 'E2'] end) then
        v_reasons := array_append(v_reasons, 'class_incompatible');
      end if;
      v_lic_ok := cardinality(v_reasons) = 0;
    end if;
  end if;

  -- vehicle / plate
  v_declared := _plate_normalize(v.vehicle_plate);
  if v.vehicle_photo_path is null or v_declared = '' then
    v_missing := true;
  elsif pr is null then
    null;
  else
    select e into v_best from jsonb_array_elements(coalesce(pr -> 'plates', '[]')) e
      order by (_plate_normalize(e ->> 'text') = v_declared) desc, (e ->> 'confidence')::numeric desc nulls last limit 1;
    v_p := _plate_normalize(v_best ->> 'text');
    if v_best is null or v_p = '' then
      v_retake := coalesce(v_retake, 'vehicle'); v_reasons := array_append(v_reasons, 'plate_unreadable');
    elsif v_p = v_declared and coalesce((v_best ->> 'confidence')::numeric, 0) >= 0.85 then
      v_plate_ok := true;
    elsif v_p = v_declared then
      v_reasons := array_append(v_reasons, 'plate_low_confidence');
    elsif _plate_near(v_p, v_declared) then
      v_reasons := array_append(v_reasons, 'plate_ambiguous');
    else
      v_reasons := array_append(v_reasons, 'plate_mismatch');
    end if;
  end if;

  if v_retake is not null and v.attempts >= 3 then
    v_reasons := array_append(v_reasons, 'repeated_retakes');
  end if;
  v_status := case
    when cardinality(array_remove(array_remove(array_remove(v_reasons,
           'licence_unreadable'), 'licence_fields_missing'), 'plate_unreadable')) > 0 then 'needs_review'
    when v_retake is not null then 'not_started'
    when v_missing then 'not_started'
    when v_lic_ok and v_plate_ok then 'verified'
    else 'pending' end;

  update driver_marketplace_verifications
     set status = v_status,
         retake = case when v_status = 'not_started' then v_retake end,
         reasons = v_reasons, updated_at = now()
   where user_id = p_user;
end $$;
