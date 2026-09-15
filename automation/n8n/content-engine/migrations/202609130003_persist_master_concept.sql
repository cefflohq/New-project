-- CEFFLO Phase 03 -- persist the Master Concept (Core Experiment) so
-- downstream Marketing Memory writes can satisfy their foreign key.
-- Source: Founder decision 2026-09-11, "Option (a)" -- add the missing
-- master_concepts persistence to CEFFLO - 03 - Master Concept Builder
-- rather than relax the marketing_memory FK.
--
-- Root cause this fixes: cefflo_content_engine.master_concepts has FKs to
-- both content_engine_runs(run_id) and content_angles(angle_id)
-- (202609100001_content_engine_roi.sql). Nothing in the existing 16-workflow
-- family ever wrote to any of these three tables before this migration --
-- only marketing_memory and content_engine_events (via CEFFLO - 10 and
-- CEFFLO - 99) had Postgres nodes at all. This function persists all three
-- rows, in FK dependency order, from the single envelope JSONB already
-- available at CEFFLO - 03's "Build Core Experiment" node -- no new table,
-- no new schema, no parallel persistence model.
--
-- Idempotent: reruns of the same run_id/angle_id/master_concept_id update
-- rather than duplicate or error (ON CONFLICT), matching the existing
-- SECURITY DEFINER pattern of persist_marketing_memory/log_event.

BEGIN;

CREATE OR REPLACE FUNCTION cefflo_content_engine.persist_master_concept(p_payload JSONB)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cefflo_content_engine, pg_temp
AS $$
DECLARE
  v_run_id UUID := (p_payload->>'run_id')::uuid;
  v_angle_id TEXT := p_payload->>'angle_id';
  v_master_concept_id TEXT := p_payload->>'master_concept_id';
  v_angle JSONB := p_payload->'selected_angles'->0;
BEGIN
  IF v_run_id IS NULL THEN RAISE EXCEPTION 'ERROR_VALIDATION: run_id is required to persist a Master Concept'; END IF;
  IF v_angle_id IS NULL THEN RAISE EXCEPTION 'ERROR_VALIDATION: angle_id is required to persist a Master Concept'; END IF;
  IF v_master_concept_id IS NULL THEN RAISE EXCEPTION 'ERROR_VALIDATION: master_concept_id is required to persist a Master Concept'; END IF;

  -- 1. content_engine_runs -- the run this concept belongs to.
  INSERT INTO cefflo_content_engine.content_engine_runs (
    run_id, task_id, campaign_id, objective, market, language, status,
    concepts_required, retry_count, created_at, updated_at
  ) VALUES (
    v_run_id,
    coalesce((p_payload->>'task_id')::uuid, v_run_id),
    NULLIF(p_payload->>'campaign_id', ''),
    coalesce(p_payload->>'objective', 'unspecified'),
    coalesce(p_payload->>'market', 'unspecified'),
    coalesce(p_payload->>'language', 'unspecified'),
    coalesce(p_payload->>'status', 'CONCEPT_READY'),
    coalesce((p_payload->>'concepts_required')::int, 1),
    coalesce((p_payload->>'retry_count')::int, 0),
    coalesce((p_payload->>'created_at')::timestamptz, now()),
    coalesce((p_payload->>'updated_at')::timestamptz, now())
  )
  ON CONFLICT (run_id) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at;

  -- 2. content_angles -- the selected Research angle this concept was built from.
  INSERT INTO cefflo_content_engine.content_angles (
    angle_id, run_id, topic, audience, pain_or_desire, angle, hook_direction,
    priority_score, duplication_score, source_basis, selected, created_at
  ) VALUES (
    v_angle_id, v_run_id,
    coalesce(v_angle->>'topic', 'unspecified'),
    coalesce(v_angle->>'audience', 'unspecified'),
    coalesce(v_angle->>'pain_or_desire', 'unspecified'),
    coalesce(v_angle->>'angle', 'unspecified'),
    coalesce(v_angle->>'hook_direction', 'unspecified'),
    (v_angle->>'priority_score')::numeric,
    (v_angle->>'duplication_score')::numeric,
    coalesce(v_angle->'source_basis', '[]'::jsonb),
    TRUE,
    coalesce((p_payload->>'created_at')::timestamptz, now())
  )
  ON CONFLICT (angle_id) DO NOTHING;

  -- 3. master_concepts -- the Core Experiment itself.
  INSERT INTO cefflo_content_engine.master_concepts (
    master_concept_id, run_id, angle_id, core_message, problem, insight,
    cefflo_relevance, truth_basis, hook_direction, cta, creative_direction,
    allowed_claims, prohibited_claims, source_references, status,
    created_at, updated_at
  ) VALUES (
    v_master_concept_id, v_run_id, v_angle_id,
    coalesce(p_payload->>'core_message', 'unspecified'),
    coalesce(p_payload->>'problem', 'unspecified'),
    coalesce(p_payload->>'insight', 'unspecified'),
    coalesce(p_payload->>'cefflo_relevance', 'unspecified'),
    coalesce(p_payload->'truth_basis', '[]'::jsonb),
    coalesce(p_payload->>'hook_direction', 'unspecified'),
    coalesce(p_payload->>'cta', 'unspecified'),
    coalesce(p_payload->>'creative_direction', 'unspecified'),
    coalesce(p_payload->'allowed_claims', '[]'::jsonb),
    coalesce(p_payload->'prohibited_claims', '[]'::jsonb),
    coalesce(p_payload->'source_references', '[]'::jsonb),
    coalesce(p_payload->>'status', 'CONCEPT_READY'),
    coalesce((p_payload->>'created_at')::timestamptz, now()),
    coalesce((p_payload->>'updated_at')::timestamptz, now())
  )
  ON CONFLICT (master_concept_id) DO UPDATE SET
    core_message = EXCLUDED.core_message,
    problem = EXCLUDED.problem,
    insight = EXCLUDED.insight,
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at;

  RETURN v_master_concept_id;
END;
$$;

-- No anon/authenticated GRANT -- this function is called only by n8n's
-- Postgres node (connects as the table owner), matching the existing
-- persist_marketing_memory/log_event functions, neither of which grants to
-- those roles either.

COMMIT;
