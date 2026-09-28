-- D-74 fix: a missing (null) recovery reason must be refused. In
-- 202609280009 recovery_reason_valid(null, ...) returned null, and
-- "if not null" does not raise, so Replace Rider / Outsource accepted a
-- null reason. Now strictly true/false.
create or replace function public.recovery_reason_valid(p_reason text, p_note text) returns boolean
language sql immutable
as $$
  select coalesce(
    p_reason in ('rider_unavailable', 'no_show', 'sick', 'vehicle_issue', 'emergency', 'other')
      and (p_reason <> 'other' or nullif(trim(coalesce(p_note, '')), '') is not null),
    false)
$$;
revoke all on function public.recovery_reason_valid(text, text) from public, anon, authenticated;
