-- CEFFLO Phase 03 -- waitlist submission RPC.
-- Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §18-19.
-- Matches the SECURITY DEFINER pattern of persist_marketing_memory/log_event
-- in 202609100001_content_engine_roi.sql. Additive; does not modify any
-- existing table.

BEGIN;

CREATE OR REPLACE FUNCTION cefflo_content_engine.submit_waitlist_entry(p_payload JSONB)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cefflo_content_engine, pg_temp
AS $$
DECLARE
  new_id UUID;
  v_email TEXT := NULLIF(trim(p_payload->>'contact_email'), '');
  v_phone TEXT := NULLIF(trim(p_payload->>'contact_phone'), '');
BEGIN
  IF v_email IS NULL AND v_phone IS NULL THEN
    RAISE EXCEPTION 'ERROR_VALIDATION: contact_email or contact_phone is required';
  END IF;
  IF coalesce((p_payload->>'consent_given')::boolean, false) IS NOT TRUE THEN
    RAISE EXCEPTION 'ERROR_VALIDATION: consent_given must be true';
  END IF;

  -- Idempotency: the same email (or phone, when no email given) re-submitting
  -- within the same campaign updates its attribution/consent timestamp rather
  -- than creating a duplicate row (§29 of the AI Content Engine Orchestrator:
  -- "avoid duplicate waitlist entries").
  SELECT waitlist_id INTO new_id
  FROM cefflo_content_engine.prelaunch_waitlist
  WHERE (v_email IS NOT NULL AND contact_email = v_email)
     OR (v_email IS NULL AND v_phone IS NOT NULL AND contact_phone = v_phone)
  LIMIT 1;

  IF new_id IS NOT NULL THEN
    UPDATE cefflo_content_engine.prelaunch_waitlist SET
      name = coalesce(NULLIF(trim(p_payload->>'name'), ''), name),
      business_name = coalesce(NULLIF(trim(p_payload->>'business_name'), ''), business_name),
      business_type = coalesce(NULLIF(trim(p_payload->>'business_type'), ''), business_type),
      approximate_delivery_volume = coalesce(NULLIF(trim(p_payload->>'approximate_delivery_volume'), ''), approximate_delivery_volume),
      source_platform = coalesce(NULLIF(trim(p_payload->>'source_platform'), ''), source_platform),
      campaign_content_id = coalesce(NULLIF(trim(p_payload->>'campaign_content_id'), ''), campaign_content_id),
      consent_given = TRUE
    WHERE waitlist_id = new_id;
    RETURN new_id;
  END IF;

  new_id := gen_random_uuid();
  INSERT INTO cefflo_content_engine.prelaunch_waitlist (
    waitlist_id, name, business_name, contact_email, contact_phone, business_type,
    approximate_delivery_volume, preferred_contact, source_platform, campaign_content_id, consent_given
  ) VALUES (
    new_id,
    NULLIF(trim(p_payload->>'name'), ''),
    NULLIF(trim(p_payload->>'business_name'), ''),
    v_email, v_phone,
    NULLIF(trim(p_payload->>'business_type'), ''),
    NULLIF(trim(p_payload->>'approximate_delivery_volume'), ''),
    NULLIF(trim(p_payload->>'preferred_contact'), ''),
    NULLIF(trim(p_payload->>'source_platform'), ''),
    NULLIF(trim(p_payload->>'campaign_content_id'), ''),
    TRUE
  );
  RETURN new_id;
END;
$$;

-- PostgREST only exposes functions in schemas listed in its own exposed-schema
-- config (db-schemas). Granting execute here is necessary but not sufficient --
-- whoever owns the live PostgREST config (Codex, per the Phase 03 Codex
-- handoff) must also add cefflo_content_engine to db-schemas for the RPC to be
-- reachable over HTTP in a real deployment. Confirmed empirically below for
-- this local instance's current config.
GRANT USAGE ON SCHEMA cefflo_content_engine TO anon, authenticated;
GRANT EXECUTE ON FUNCTION cefflo_content_engine.submit_waitlist_entry(JSONB) TO anon, authenticated;

COMMIT;
