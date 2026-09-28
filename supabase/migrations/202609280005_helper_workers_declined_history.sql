-- D-74 follow-up. 202609280004 retired the accountless Helper secrets but
-- also relabelled Helpers who had DECLINED their invitation as 'revoked'
-- (their invite hash was still stored). Restore the recorded outcome from
-- the audit trail (helper.invite_declined events); the secrets stay cleared.
update public.helper_workers h set
  status = 'declined',
  revoked_at = null,
  updated_at = now()
where h.status = 'revoked'
  and exists (
    select 1 from public.delivery_events e
    where e.event_type = 'helper.invite_declined'
      and e.business_id = h.business_id
      and e.metadata->>'helper_id' = h.id::text
  )
  and not exists (
    select 1 from public.delivery_events e
    where e.event_type in ('helper.invite_accepted', 'helper.revoked')
      and e.business_id = h.business_id
      and e.metadata->>'helper_id' = h.id::text
  );
