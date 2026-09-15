-- S4-04 Batch 2: stop public_tracking from exposing the raw internal POD
-- storage path to Customer/Public callers. Replace with a boolean signal;
-- give the tracking-pod Edge Function a service_role-only lookup for the
-- real path it needs to create a signed URL. No other field/behavior changes.

create or replace function public.public_tracking(p_token text) returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'order_id', o.public_ref,
    'store_name', b.name,
    'status', o.delivery_status,
    'eta', o.estimated_arrival_at,
    'rider_name', r.name,
    'completed_at', o.completed_at,
    'pod_available', (o.delivery_status = 'delivered' and s.pod_storage_path is not null),
    'rating_submitted', rt.id is not null
  )
  from tracking_tokens t
  join orders o on o.id = t.order_id
  join businesses b on b.id = o.business_id
  left join riders r on r.id = o.assigned_rider_id
  join delivery_stops s on s.order_id = o.id
  left join ratings rt on rt.order_id = o.id
  where t.token_hash = encode(digest(p_token, 'sha256'), 'hex')
    and t.revoked_at is null
    and (t.expires_at is null or t.expires_at > now())
$$;

-- Internal-only lookup: same token/expiry/revocation validation as
-- public_tracking, but returns the raw storage path. Never granted to
-- anon/authenticated, so the raw path never reaches a public contract.
create function public.internal_tracking_pod_path(p_token text) returns text
language sql
stable
security definer
set search_path = public, extensions
as $$
  select case when o.delivery_status = 'delivered' then s.pod_storage_path end
  from tracking_tokens t
  join orders o on o.id = t.order_id
  join delivery_stops s on s.order_id = o.id
  where t.token_hash = encode(digest(p_token, 'sha256'), 'hex')
    and t.revoked_at is null
    and (t.expires_at is null or t.expires_at > now())
$$;

-- Supabase grants EXECUTE on every new function directly to anon/authenticated/
-- service_role via default privileges (not via the PUBLIC pseudo-role), so all
-- three must be named explicitly here or the revoke is a silent no-op.
revoke all on function public.internal_tracking_pod_path(text) from public, anon, authenticated;
grant execute on function public.internal_tracking_pod_path(text) to service_role;
