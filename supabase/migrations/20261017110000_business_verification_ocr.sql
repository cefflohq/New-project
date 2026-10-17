-- Business verification, polished (Founder 2026-10-17): the owner only
-- snaps the IC front and back with the camera; SSM is optional. The owner's
-- name and IC number are read from the IC photo by the server
-- (business-verification function, Google Vision), never typed.
alter table public.business_verifications alter column ssm_number drop not null;
alter table public.business_verifications alter column owner_name drop not null;
alter table public.business_verifications alter column owner_ic_last4 drop not null;
alter table public.business_verifications alter column ssm_path drop not null;
alter table public.business_verifications drop constraint if exists business_verifications_ssm_number_check;
alter table public.business_verifications drop constraint if exists business_verifications_owner_ic_last4_check;
alter table public.business_verifications add constraint business_verifications_owner_ic_last4_check
  check (owner_ic_last4 is null or owner_ic_last4 ~ '^[0-9]{4}$');
-- 'read' = name and IC read from the photo; 'unread' = Cefflo reads it by eye.
alter table public.business_verifications add column if not exists ocr_status text not null default 'unread'
  check (ocr_status in ('read','unread'));

-- Submission now goes only through the function, which reads the IC.
revoke execute on function public.submit_business_verification(uuid, text, text, text, text, text, text) from authenticated;

create or replace function public.admin_list_business_verifications()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('business_id', v.business_id, 'business_name', b.name,
            'ssm_number', v.ssm_number, 'owner_name', v.owner_name, 'owner_ic_last4', v.owner_ic_last4,
            'ssm_path', v.ssm_path, 'ic_front_path', v.ic_front_path, 'ic_back_path', v.ic_back_path,
            'ocr_status', v.ocr_status, 'status', v.status, 'reject_reason', v.reject_reason,
            'submitted_at', v.submitted_at, 'reviewed_at', v.reviewed_at, 'owner_email', u.email)
          order by (v.status = 'pending') desc, v.submitted_at desc), '[]'::jsonb)
    from business_verifications v join businesses b on b.id = v.business_id
    left join auth.users u on u.id = v.submitted_by);
end $$;

create or replace function public.my_business_verification(p_business_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not is_business_member(p_business_id) then null else
    (select jsonb_build_object('status', v.status, 'owner_name', v.owner_name, 'owner_ic_last4', v.owner_ic_last4,
                               'has_ssm', v.ssm_path is not null, 'reject_reason', v.reject_reason,
                               'submitted_at', v.submitted_at, 'reviewed_at', v.reviewed_at)
       from business_verifications v where v.business_id = p_business_id) end
$$;
