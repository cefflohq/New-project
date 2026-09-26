-- S4-06 Batch 5a: build_rider_run -- additive, all-or-nothing Vendor Run
-- Builder orchestration RPC. Reuses attach_order_to_session and
-- assign_rider completely unchanged for the actual per-order mutation and
-- their existing events; adds exactly one new correlated run.built event
-- per successful call. No schema change beyond one partial unique index.
--
-- Idempotency is a true key+payload ledger, not a state-based shortcut:
-- matching current order/session/rider state is never itself treated as
-- evidence that an incoming request is a retry. A committed operation is
-- proven only by an existing run.built event carrying the same
-- idempotency key, with its stored payload compared against the incoming
-- request before any success is returned.

-- Enforces true, DB-level uniqueness of the idempotency key across all
-- run.built events -- the correctness backstop under genuine concurrency,
-- not merely a lookup optimization. No new ledger table: delivery_events
-- is already this project's canonical event/audit log.
create unique index run_built_idempotency_key_idx
  on public.delivery_events ((metadata->>'idempotency_key'))
  where event_type = 'run.built';

create function public.build_rider_run(
  p_delivery_session_id uuid,
  p_rider_id uuid,
  p_order_ids uuid[],
  p_idempotency_key uuid
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  s delivery_sessions;
  r riders;
  requested_ids uuid[];
  requested_count int;
  distinct_count int;
  locked_count int;
  eligible_count int;
  existing_event delivery_events;
  existing_session_id uuid;
  existing_rider_id uuid;
  existing_order_ids uuid[];
  oid uuid;
begin
  if p_idempotency_key is null then
    raise exception 'idempotency key required';
  end if;
  if p_order_ids is null or array_length(p_order_ids,1) is null or array_length(p_order_ids,1) = 0 then
    raise exception 'no orders selected';
  end if;

  -- Normalize once (sorted, deduped) -- the canonical form used both for
  -- the duplicate-input check and for every idempotency payload comparison.
  requested_count := array_length(p_order_ids,1);
  select array_agg(x order by x) into requested_ids from (select distinct unnest(p_order_ids) as x) d;
  distinct_count := array_length(requested_ids,1);
  if requested_count <> distinct_count then
    raise exception 'duplicate order ids';
  end if;

  -- Idempotency-key lookup FIRST, before any other validation: a matching
  -- committed run.built proves a retry regardless of current state.
  select * into existing_event
    from delivery_events
    where event_type = 'run.built' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
    limit 1;

  if existing_event.id is not null then
    existing_session_id := (existing_event.metadata->>'delivery_session_id')::uuid;
    existing_rider_id := (existing_event.metadata->>'rider_id')::uuid;
    select array_agg((x)::uuid order by (x)::uuid) into existing_order_ids
      from jsonb_array_elements_text(existing_event.metadata->'order_ids') as x;

    if existing_session_id = p_delivery_session_id
       and existing_rider_id = p_rider_id
       and existing_order_ids = requested_ids then
      return jsonb_build_object(
        'delivery_session_id', existing_session_id,
        'rider_id', existing_rider_id,
        'order_count', array_length(existing_order_ids,1)
      );
    else
      raise exception 'idempotency key conflict';
    end if;
  end if;

  -- Genuinely new key: normal validation path.
  select * into s from delivery_sessions where id = p_delivery_session_id for update;
  if s.id is null or not is_business_member(s.business_id) then
    raise exception 'forbidden';
  end if;
  if s.status not in ('planned','active') then
    raise exception 'session not open';
  end if;

  select * into r from riders where id = p_rider_id;
  if r.id is null or r.business_id is distinct from s.business_id or r.status <> 'active' then
    raise exception 'invalid rider';
  end if;

  -- Lock and revalidate the complete selected set atomically, in one
  -- statement, before any mutation. locked_count catches nonexistent ids;
  -- eligible_count re-applies the canonical eligibility rule to the same
  -- locked snapshot. Both must equal the full requested count, or nothing
  -- is mutated -- this is the all-or-nothing guarantee.
  -- FOR UPDATE cannot be combined with an aggregate in one SELECT; lock the
  -- row-level set in a CTE, then aggregate over the locked result.
  with locked as (
    select business_id, approved_at, assigned_rider_id, delivery_status
    from orders
    where id = any(requested_ids)
    for update
  )
  select
    count(*),
    count(*) filter (
      where business_id = s.business_id
        and approved_at is not null
        and assigned_rider_id is null
        and delivery_status = 'created'
    )
  into locked_count, eligible_count
  from locked;

  if locked_count <> distinct_count or eligible_count <> distinct_count then
    -- Concurrency refinement: a racing call sharing this exact key and
    -- payload may have committed while this call was blocked on the row
    -- lock above. Re-check before reporting an eligibility conflict, so
    -- two simultaneous identical Confirm-Run actions both resolve to the
    -- same success rather than one failing.
    select * into existing_event
      from delivery_events
      where event_type = 'run.built' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
      limit 1;

    if existing_event.id is not null then
      existing_session_id := (existing_event.metadata->>'delivery_session_id')::uuid;
      existing_rider_id := (existing_event.metadata->>'rider_id')::uuid;
      select array_agg((x)::uuid order by (x)::uuid) into existing_order_ids
        from jsonb_array_elements_text(existing_event.metadata->'order_ids') as x;

      if existing_session_id = p_delivery_session_id
         and existing_rider_id = p_rider_id
         and existing_order_ids = requested_ids then
        return jsonb_build_object(
          'delivery_session_id', existing_session_id,
          'rider_id', existing_rider_id,
          'order_count', array_length(existing_order_ids,1)
        );
      else
        raise exception 'idempotency key conflict';
      end if;
    end if;

    raise exception 'orders no longer eligible';
  end if;

  -- All-or-nothing mutation: reuse the existing per-order contracts
  -- completely unchanged, preserving the canonical attach-before-assign
  -- ordering (assign_rider snapshots delivery_session_id onto the new
  -- rider_assignments row at insert time).
  foreach oid in array requested_ids loop
    perform attach_order_to_session(oid, p_delivery_session_id);
    perform assign_rider(oid, p_rider_id);
  end loop;

  -- Defense-in-depth backstop for the narrow case of the same key reused
  -- across two genuinely disjoint (non-lock-overlapping) order sets
  -- racing concurrently: the partial unique index is the actual
  -- correctness guarantee; this turns a raw constraint violation into the
  -- same clean, factual error used everywhere else above.
  begin
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (
        s.business_id, 'run.built', auth.uid(), 'vendor',
        jsonb_build_object(
          'delivery_session_id', p_delivery_session_id,
          'rider_id', p_rider_id,
          'order_ids', to_jsonb(requested_ids),
          'idempotency_key', p_idempotency_key
        )
      );
  exception when unique_violation then
    raise exception 'idempotency key conflict';
  end;

  return jsonb_build_object(
    'delivery_session_id', p_delivery_session_id,
    'rider_id', p_rider_id,
    'order_count', distinct_count
  );
end;
$$;

revoke all on function public.build_rider_run(uuid,uuid,uuid[],uuid) from public, anon, authenticated;
grant execute on function public.build_rider_run(uuid,uuid,uuid[],uuid) to authenticated;
