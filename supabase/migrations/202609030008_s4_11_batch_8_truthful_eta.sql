-- S4-11 Batch 8 (Grow V1 Flow 2, A5): truthful ETA.
--
-- Flow 1 finding (audit report §10): orders.estimated_arrival_at is READ by
-- public_tracking but no function in this schema's history has ever SET
-- it -- always effectively null. Founder Gate decision (Flow 1 scope
-- freeze): a range/state when that is all evidence supports; never
-- fabricated precision.
--
-- Deliberately does NOT use rider_locations (live GPS): Flow 1 found no
-- confirmed live frontend write path for it (git history already contains
-- one explicit "Remove false Rider GPS tracking claim" correction) --
-- building an ETA on top of data that may not actually be flowing would
-- repeat exactly that mistake. Instead: compute live, at read time (never
-- stored, never stale) from what IS canonical and real -- the locked stop
-- sequence (S4-06.7) and how many not-yet-delivered stops precede this one
-- in the same Rider's active run. Distance/travel-time input stays
-- optional per the Master MD (§4 "routing/distance inputs where selected
-- architecture needs it") -- this V1 pass uses stop-count only, which is
-- honestly "a range that is all evidence supports," not a routing engine.

-- Coarse, documented per-stop duration bounds -- a bounded operational
-- assumption (same class of decision as A3's default vehicle capacities),
-- not derived from measured data, and intentionally wide rather than
-- falsely precise. Fully replaceable by a real routing-provider-informed
-- estimate in a future batch without changing this function's contract.
create function public.compute_order_eta(p_order_id uuid) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  o orders;
  s delivery_stops;
  preceding_count integer;
  earliest_minutes integer;
  latest_minutes integer;
begin
  select * into o from orders where id = p_order_id;
  if o.id is null then
    raise exception 'order not found';
  end if;
  select * into s from delivery_stops where order_id = p_order_id;

  if o.delivery_status = 'delivered' then
    return jsonb_build_object('state', 'completed');
  end if;
  if o.delivery_status = 'cancelled' then
    return jsonb_build_object('state', 'cancelled');
  end if;
  if s.status = 'issue' or o.delivery_status = 'issue' then
    return jsonb_build_object('state', 'exception_in_progress');
  end if;
  if o.delivery_status not in ('picked_up','out_for_delivery','arrived') then
    return jsonb_build_object('state', 'not_yet_dispatched');
  end if;
  if s.sequence is null or s.assignment_id is null then
    -- Dispatched in backend status terms but not part of a locked,
    -- sequenced run (should not normally happen given build_rider_run's
    -- own guarantees, but the ETA function must never assume it) --
    -- honest "we don't have enough structure to bound a time" state.
    return jsonb_build_object('state', 'in_progress_no_time_estimate');
  end if;
  if o.delivery_status = 'arrived' then
    return jsonb_build_object('state', 'arriving_now');
  end if;

  -- "Same run" is (delivery_session_id, rider_id) via rider_assignments --
  -- NOT delivery_stops.assignment_id equality. assign_rider inserts one
  -- fresh rider_assignments row PER ORDER (build_rider_run calls it once
  -- per selected order), so every order in a run has its OWN, distinct
  -- assignment_id; this exact (session_id, rider_id) join is the same
  -- pattern save_run_sequence itself already uses to define "this Rider's
  -- current run" (S4-06 Batch 2).
  select count(*) into preceding_count
    from delivery_stops ds
    join rider_assignments ra_other on ra_other.id = ds.assignment_id
    join rider_assignments ra_self on ra_self.id = s.assignment_id
    where ra_other.delivery_session_id = ra_self.delivery_session_id
      and ra_other.rider_id = ra_self.rider_id
      and ds.sequence < s.sequence
      and ds.status not in ('delivered','cancelled');

  -- Coarse bounds: 5-15 min for this stop's own approach/service, plus
  -- 8-20 min per still-pending preceding stop. Documented, tunable,
  -- never presented as more precise than "a range."
  earliest_minutes := 5 + preceding_count * 8;
  latest_minutes := 15 + preceding_count * 20;

  return jsonb_build_object(
    'state', 'estimated_range',
    'earliest', (now() + make_interval(mins => earliest_minutes)),
    'latest', (now() + make_interval(mins => latest_minutes)),
    'stops_ahead', preceding_count
  );
end;
$$;

revoke all on function public.compute_order_eta(uuid) from public, anon, authenticated;
grant execute on function public.compute_order_eta(uuid) to authenticated, anon;

-- public_tracking: replace the dead estimated_arrival_at read with the
-- live-computed truthful ETA object. Identical to the current version in
-- every other respect (same join shape, same token-hash lookup, same
-- revoked/expired guard).
create or replace function public.public_tracking(p_token text) returns jsonb
language sql stable security definer set search_path = public, extensions
as $$
select jsonb_build_object(
  'order_id', o.public_ref,
  'store_name', b.name,
  'status', o.delivery_status,
  'eta', compute_order_eta(o.id),
  'rider_name', r.name,
  'completed_at', o.completed_at,
  'pod_path', case when o.delivery_status = 'delivered' then s.pod_storage_path end,
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
