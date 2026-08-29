-- S4-04 Batch 3: tracking-token lifecycle per Founder-locked policy.
-- create_delivery is intentionally NOT changed: leaving expires_at NULL at
-- creation already means "valid for the life of an active delivery," which
-- is exactly the approved policy (no arbitrary creation-time clock).

-- Completed delivery: bound the token to a 48-hour post-completion window.
create or replace function public.complete_delivery(p_order_id uuid,p_pod_path text,p_note text default '',p_idempotency_key text default null) returns public.orders language plpgsql security definer set search_path=public as $$declare o orders;rid uuid;begin rid=current_rider_id();select * into o from orders where id=p_order_id for update;if o.id is null or rid is null or o.assigned_rider_id is distinct from rid then raise exception 'forbidden';end if;if o.delivery_status='delivered' then return o;end if;if o.delivery_status<>'arrived' or nullif(trim(p_pod_path),'') is null then raise exception 'arrival and POD required';end if;update orders set delivery_status='delivered',completed_at=now(),updated_at=now() where id=o.id returning * into o;update delivery_stops set status='delivered',pod_storage_path=p_pod_path,pod_note=p_note,pod_captured_at=now(),pod_submitted_by=auth.uid(),completed_at=now(),updated_at=now() where order_id=o.id;update tracking_tokens set expires_at=now()+interval '48 hours' where order_id=o.id;insert into delivery_events(business_id,order_id,delivery_stop_id,assignment_id,event_type,from_status,to_status,actor_user_id,actor_role,metadata)select o.business_id,o.id,s.id,s.assignment_id,'delivery.completed','arrived','delivered',auth.uid(),'rider',jsonb_build_object('idempotency_key',p_idempotency_key) from delivery_stops s where s.order_id=o.id;return o;end$$;

-- Revocation: Owner or Operator/Staff (business-scoped), never Rider/Customer.
-- Never returns the token row (which would leak token_hash) — boolean only.
create function public.revoke_tracking_token(p_order_id uuid) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
  t public.tracking_tokens;
begin
  select * into o from public.orders where id = p_order_id;
  if o.id is null or not public.is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;

  select * into t from public.tracking_tokens where order_id = p_order_id for update;
  if t.id is null then
    raise exception 'tracking token not found';
  end if;

  update public.tracking_tokens set revoked_at = now() where order_id = p_order_id;

  insert into public.delivery_events(
    business_id, order_id, event_type, actor_user_id, actor_role, metadata
  ) values (
    o.business_id, o.id, 'tracking_token_revoked', auth.uid(), 'vendor',
    jsonb_build_object('token_id', t.id)
  );

  return true;
end;
$$;

-- Rotation: Owner or Operator/Staff (business-scoped). Generates a fresh
-- cryptographically random opaque token via the same gen_random_bytes(32)
-- pattern create_delivery already uses; stores only its hash; returns the
-- raw token once (never the hash, never the internal order id).
-- Expiry: active order -> NULL (normal active-delivery policy); already
-- delivered order -> a fresh 48-hour window from rotation time.
create function public.rotate_tracking_token(p_order_id uuid) returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  o public.orders;
  t public.tracking_tokens;
  new_token text;
  new_expiry timestamptz;
begin
  select * into o from public.orders where id = p_order_id;
  if o.id is null or not public.is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;

  select * into t from public.tracking_tokens where order_id = p_order_id for update;
  if t.id is null then
    raise exception 'tracking token not found';
  end if;

  new_token := encode(gen_random_bytes(32), 'hex');
  new_expiry := case when o.delivery_status = 'delivered' then now() + interval '48 hours' else null end;

  update public.tracking_tokens set
    token_hash = encode(digest(new_token, 'sha256'), 'hex'),
    expires_at = new_expiry,
    revoked_at = null
  where order_id = p_order_id;

  insert into public.delivery_events(
    business_id, order_id, event_type, actor_user_id, actor_role, metadata
  ) values (
    o.business_id, o.id, 'tracking_token_rotated', auth.uid(), 'vendor',
    jsonb_build_object('token_id', t.id)
  );

  return new_token;
end;
$$;

-- Explicit revoke from anon/authenticated too: this Supabase instance grants
-- EXECUTE on every new function directly to anon/authenticated/service_role
-- via default privileges (not via PUBLIC), so revoking from PUBLIC alone is
-- a silent no-op (discovered and documented in the Batch-2 migration).
revoke all on function public.revoke_tracking_token(uuid) from public, anon, authenticated;
revoke all on function public.rotate_tracking_token(uuid) from public, anon, authenticated;
grant execute on function public.revoke_tracking_token(uuid) to authenticated;
grant execute on function public.rotate_tracking_token(uuid) to authenticated;
