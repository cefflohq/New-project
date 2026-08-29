-- S4-04 Batch 5.2: wire per-token rate limiting into public_tracking only.
-- Limit: 10 requests / 60 seconds per token (Founder-approved, revised down
-- from an initial 20 after the Customer Tracking on-demand-refresh policy
-- update removed continuous 15s polling -- legitimate per-token traffic is
-- now occasional bursts, not a sustained stream). Limiter
-- infrastructure failures fail OPEN (never block a legitimate lookup); a
-- deliberate over-limit result fails closed (raises, request denied). Token
-- validity/expiry/revocation behavior is completely unchanged. On any
-- not-found outcome (invalid/expired/revoked token), records a bounded,
-- aggregate-only telemetry count -- never used to deny a request.
--
-- Converted from `language sql` to `language plpgsql` because gating logic
-- (check-then-branch) requires real control flow; the function now performs
-- a write (the rate-limit counter) so `stable` no longer applies.
create or replace function public.public_tracking(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  key text;
  allowed boolean;
  result jsonb;
begin
  key := encode(digest(p_token, 'sha256'), 'hex');

  begin
    allowed := check_rate_limit(key, 'public_tracking', 60, 10);
  exception when others then
    allowed := true;
  end;

  if not allowed then
    raise exception 'rate limited';
  end if;

  select jsonb_build_object(
    'order_id', o.public_ref,
    'store_name', b.name,
    'status', o.delivery_status,
    'eta', o.estimated_arrival_at,
    'rider_name', r.name,
    'completed_at', o.completed_at,
    'pod_available', (o.delivery_status = 'delivered' and s.pod_storage_path is not null),
    'rating_submitted', rt.id is not null
  ) into result
  from tracking_tokens t
  join orders o on o.id = t.order_id
  join businesses b on b.id = o.business_id
  left join riders r on r.id = o.assigned_rider_id
  join delivery_stops s on s.order_id = o.id
  left join ratings rt on rt.order_id = o.id
  where t.token_hash = key
    and t.revoked_at is null
    and (t.expires_at is null or t.expires_at > now());

  if result is null then
    perform record_invalid_lookup_telemetry('public_tracking');
  end if;

  return result;
end;
$$;
