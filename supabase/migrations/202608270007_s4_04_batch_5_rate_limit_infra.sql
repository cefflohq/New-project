-- S4-04 Batch 5.1: rate-limiting infrastructure only. Purely additive --
-- nothing is wired to any consumer yet (that's Batches 5.2-5.4).

-- Per-token/action enforcement counters. Bounded by construction: one row
-- per (key_hash, action, window_start), never per raw request. key_hash is
-- always a SHA-256 digest (reused from the token's own hash where called
-- from token-scoped functions) -- the raw token is never stored here.
create table public.rate_limit_counters(
  key_hash text not null,
  action text not null,
  window_start timestamptz not null,
  request_count int not null default 1,
  primary key (key_hash, action, window_start)
);
alter table public.rate_limit_counters enable row level security;
-- No policies, no grants to anon/authenticated: only reachable via
-- check_rate_limit() below, which runs as this table's owner.

-- Non-enforcing telemetry for invalid/expired/revoked-token lookups.
-- Deliberately NOT used to deny any request (Founder decision: a shared
-- enforcing bucket would eventually punish legitimate customers hitting
-- naturally stale links as traffic scales, and cannot distinguish that from
-- abuse without a trustworthy source signal, which this platform does not
-- provide by default). Aggregate-only: one row per (action, window_start),
-- never keyed by the individual attempted token, so cardinality stays
-- bounded no matter how many distinct invalid tokens are ever presented.
create table public.invalid_lookup_telemetry(
  action text not null,
  window_start timestamptz not null,
  request_count int not null default 1,
  primary key (action, window_start)
);
alter table public.invalid_lookup_telemetry enable row level security;
-- No policies, no client grants: written only by record_invalid_lookup_telemetry().

-- Atomic check-and-increment for a per-key/action fixed-window limit.
-- Returns true if this request is within the limit (and counts it), false
-- if the limit is already exceeded. Callers MUST treat any exception raised
-- by calling this function as fail-open (allowed=true) -- see call sites in
-- public_tracking/submit_rating/the tracking-pod Edge Function. This keeps
-- limiter infrastructure failures from becoming a denial-of-service vector
-- against legitimate customers, while the separate, unrelated token
-- validity/expiry/revocation check remains fail-closed and unchanged.
create function public.check_rate_limit(
  p_key_hash text,
  p_action text,
  p_window_seconds int,
  p_max_requests int
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  bucket timestamptz;
  current_count int;
begin
  bucket := to_timestamp(floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  insert into rate_limit_counters(key_hash, action, window_start, request_count)
  values (p_key_hash, p_action, bucket, 1)
  on conflict (key_hash, action, window_start)
  do update set request_count = rate_limit_counters.request_count + 1
  returning request_count into current_count;
  return current_count <= p_max_requests;
end;
$$;

revoke all on function public.check_rate_limit(text,text,int,int) from public, anon, authenticated;
grant execute on function public.check_rate_limit(text,text,int,int) to service_role;
-- public_tracking/submit_rating call this internally as SECURITY DEFINER
-- functions themselves -- an internal function-to-function call runs with
-- the calling function's own (owner) privileges and needs no separate grant
-- for anon/authenticated, exactly like their existing calls to
-- is_business_member()-style helpers. Only the Edge Function's direct RPC
-- call (as service_role) needs the explicit grant above.

-- Telemetry-only recorder. Never raises to the caller -- any internal
-- failure is swallowed so telemetry can never break a real operation.
create function public.record_invalid_lookup_telemetry(p_action text) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  bucket timestamptz;
begin
  bucket := to_timestamp(floor(extract(epoch from now()) / 60) * 60);
  insert into invalid_lookup_telemetry(action, window_start, request_count)
  values (p_action, bucket, 1)
  on conflict (action, window_start)
  do update set request_count = invalid_lookup_telemetry.request_count + 1;
exception when others then
  null;
end;
$$;

revoke all on function public.record_invalid_lookup_telemetry(text) from public, anon, authenticated;
grant execute on function public.record_invalid_lookup_telemetry(text) to service_role;

-- Cleanup: bounded retention via pg_cron (confirmed available on this
-- project). Enforcement counters kept 1 hour (generous vs. the 60s/600s
-- windows actually used); telemetry aggregates kept 24 hours for
-- observability. Both deletes are cheap: bounded row counts per run.
create extension if not exists pg_cron with schema extensions;

select cron.schedule(
  'cefflo_rate_limit_cleanup',
  '*/10 * * * *',
  $$
    delete from public.rate_limit_counters where window_start < now() - interval '1 hour';
    delete from public.invalid_lookup_telemetry where window_start < now() - interval '24 hours';
  $$
);
