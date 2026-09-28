BEGIN;

CREATE SCHEMA IF NOT EXISTS cefflo_content_engine;

CREATE TABLE IF NOT EXISTS cefflo_content_engine.content_engine_runs (
  run_id UUID PRIMARY KEY,
  task_id UUID NOT NULL,
  campaign_id TEXT NULL,
  objective TEXT NOT NULL,
  market TEXT NOT NULL,
  language TEXT NOT NULL,
  status TEXT NOT NULL,
  concepts_required INTEGER NOT NULL CHECK (concepts_required BETWEEN 1 AND 100),
  retry_count INTEGER NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.content_angles (
  angle_id TEXT PRIMARY KEY,
  run_id UUID NOT NULL REFERENCES cefflo_content_engine.content_engine_runs(run_id) ON DELETE CASCADE,
  topic TEXT NOT NULL,
  audience TEXT NOT NULL,
  pain_or_desire TEXT NOT NULL,
  angle TEXT NOT NULL,
  hook_direction TEXT NOT NULL,
  priority_score NUMERIC NULL,
  duplication_score NUMERIC NULL,
  source_basis JSONB NOT NULL DEFAULT '[]'::jsonb,
  selected BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.master_concepts (
  master_concept_id TEXT PRIMARY KEY CHECK (master_concept_id ~ '^CEFFLO-[0-9]{4}-W[0-9]{2}-E[0-9]{3}$'),
  run_id UUID NOT NULL REFERENCES cefflo_content_engine.content_engine_runs(run_id) ON DELETE CASCADE,
  angle_id TEXT NOT NULL REFERENCES cefflo_content_engine.content_angles(angle_id),
  core_message TEXT NOT NULL,
  problem TEXT NOT NULL,
  insight TEXT NOT NULL,
  cefflo_relevance TEXT NOT NULL,
  truth_basis JSONB NOT NULL DEFAULT '[]'::jsonb,
  hook_direction TEXT NOT NULL,
  cta TEXT NOT NULL,
  creative_direction TEXT NOT NULL,
  allowed_claims JSONB NOT NULL DEFAULT '[]'::jsonb,
  prohibited_claims JSONB NOT NULL DEFAULT '[]'::jsonb,
  source_references JSONB NOT NULL DEFAULT '[]'::jsonb,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.creative_packages (
  package_id UUID PRIMARY KEY,
  master_concept_id TEXT NOT NULL REFERENCES cefflo_content_engine.master_concepts(master_concept_id) ON DELETE CASCADE,
  lane TEXT NOT NULL CHECK (lane IN ('meta', 'tiktok', 'threads')),
  destinations JSONB NOT NULL,
  payload JSONB NOT NULL,
  qa_status TEXT NULL CHECK (qa_status IS NULL OR qa_status IN ('PASS', 'REVISE', 'REJECT')),
  revision_count INTEGER NOT NULL DEFAULT 0 CHECK (revision_count >= 0),
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  UNIQUE (master_concept_id, lane)
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.founder_reviews (
  review_id UUID PRIMARY KEY,
  master_concept_id TEXT NOT NULL REFERENCES cefflo_content_engine.master_concepts(master_concept_id) ON DELETE CASCADE,
  founder_status TEXT NOT NULL CHECK (founder_status IN ('APPROVE', 'REVISE', 'REJECT', 'HOLD')),
  founder_feedback TEXT NULL,
  revision_target JSONB NULL,
  reviewed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.publish_records (
  publish_record_id UUID PRIMARY KEY,
  content_id TEXT NOT NULL,
  master_concept_id TEXT NOT NULL REFERENCES cefflo_content_engine.master_concepts(master_concept_id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('instagram', 'facebook', 'tiktok', 'threads')),
  scheduled_time TIMESTAMPTZ NULL,
  published_time TIMESTAMPTZ NULL,
  publish_status TEXT NOT NULL CHECK (publish_status IN ('PENDING', 'SCHEDULED', 'PUBLISHED', 'FAILED', 'STUBBED')),
  external_post_id TEXT NULL,
  error_code TEXT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  UNIQUE (master_concept_id, platform)
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.content_analytics (
  analytics_id UUID PRIMARY KEY,
  content_id TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('instagram', 'facebook', 'tiktok', 'threads')),
  metrics JSONB NOT NULL,
  performance_score NUMERIC NULL,
  collected_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.marketing_memory (
  memory_id UUID PRIMARY KEY,
  content_id TEXT NOT NULL,
  master_concept_id TEXT NOT NULL REFERENCES cefflo_content_engine.master_concepts(master_concept_id) ON DELETE CASCADE,
  angle TEXT NOT NULL,
  hook TEXT NOT NULL,
  audience TEXT NOT NULL,
  content_pillar TEXT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('instagram', 'facebook', 'tiktok', 'threads')),
  format TEXT NOT NULL,
  publish_date TIMESTAMPTZ NULL,
  performance_score NUMERIC NULL,
  qa_feedback JSONB NOT NULL DEFAULT '[]'::jsonb,
  founder_feedback TEXT NULL,
  winner_or_loser TEXT NULL CHECK (winner_or_loser IS NULL OR winner_or_loser IN ('WINNER', 'LOSER')),
  lessons JSONB NOT NULL DEFAULT '[]'::jsonb,
  reuse_recommendation TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  UNIQUE (content_id, platform)
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.content_engine_events (
  event_id UUID PRIMARY KEY,
  run_id UUID NULL REFERENCES cefflo_content_engine.content_engine_runs(run_id) ON DELETE SET NULL,
  workflow_name TEXT NOT NULL,
  stage TEXT NOT NULL,
  status TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
  error_code TEXT NULL,
  error_message TEXT NULL,
  payload JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS content_engine_runs_status_updated_idx ON cefflo_content_engine.content_engine_runs(status, updated_at DESC);
CREATE INDEX IF NOT EXISTS content_angles_run_idx ON cefflo_content_engine.content_angles(run_id, selected);
CREATE INDEX IF NOT EXISTS master_concepts_run_status_idx ON cefflo_content_engine.master_concepts(run_id, status);
CREATE INDEX IF NOT EXISTS creative_packages_concept_status_idx ON cefflo_content_engine.creative_packages(master_concept_id, status);
CREATE INDEX IF NOT EXISTS founder_reviews_concept_created_idx ON cefflo_content_engine.founder_reviews(master_concept_id, created_at DESC);
CREATE INDEX IF NOT EXISTS publish_records_content_status_idx ON cefflo_content_engine.publish_records(content_id, platform, publish_status);
CREATE INDEX IF NOT EXISTS content_analytics_content_collected_idx ON cefflo_content_engine.content_analytics(content_id, platform, collected_at DESC);
CREATE INDEX IF NOT EXISTS marketing_memory_concept_platform_idx ON cefflo_content_engine.marketing_memory(master_concept_id, platform, updated_at DESC);
CREATE INDEX IF NOT EXISTS content_engine_events_run_created_idx ON cefflo_content_engine.content_engine_events(run_id, created_at DESC);
CREATE INDEX IF NOT EXISTS content_engine_events_status_created_idx ON cefflo_content_engine.content_engine_events(status, created_at DESC);

CREATE OR REPLACE FUNCTION cefflo_content_engine.persist_marketing_memory(p_payload JSONB)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  item JSONB;
  affected INTEGER := 0;
  changed INTEGER := 0;
BEGIN
  IF jsonb_typeof(p_payload->'marketing_memory_records') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'marketing_memory_records must be an array';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_payload->'marketing_memory_records')
  LOOP
    INSERT INTO cefflo_content_engine.marketing_memory (
      memory_id, content_id, master_concept_id, angle, hook, audience,
      content_pillar, platform, format, publish_date, performance_score,
      qa_feedback, founder_feedback, winner_or_loser, lessons,
      reuse_recommendation, created_at, updated_at
    ) VALUES (
      COALESCE(NULLIF(item->>'memory_id', '')::uuid, md5((item->>'content_id') || ':' || (item->>'platform'))::uuid),
      item->>'content_id', item->>'master_concept_id',
      item->>'angle', item->>'hook', item->>'audience', item->>'content_pillar',
      item->>'platform', item->>'format', (item->>'publish_date')::timestamptz,
      (item->>'performance_score')::numeric, COALESCE(item->'qa_feedback', '[]'::jsonb),
      item->>'founder_feedback', item->>'winner_or_loser',
      COALESCE(item->'lessons', '[]'::jsonb), item->>'reuse_recommendation',
      COALESCE((item->>'created_at')::timestamptz, now()),
      COALESCE((item->>'updated_at')::timestamptz, now())
    )
    ON CONFLICT (content_id, platform) DO UPDATE SET
      performance_score = EXCLUDED.performance_score,
      qa_feedback = EXCLUDED.qa_feedback,
      founder_feedback = EXCLUDED.founder_feedback,
      lessons = EXCLUDED.lessons,
      reuse_recommendation = EXCLUDED.reuse_recommendation,
      updated_at = EXCLUDED.updated_at;
    GET DIAGNOSTICS changed = ROW_COUNT;
    affected := affected + changed;
  END LOOP;
  RETURN affected;
END;
$$;

CREATE OR REPLACE FUNCTION cefflo_content_engine.log_event(p_event JSONB)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  new_id UUID;
BEGIN
  new_id := COALESCE(
    NULLIF(p_event->>'event_id', '')::uuid,
    md5(COALESCE(p_event->>'run_id', '') || ':' || COALESCE(p_event->>'workflow_name', '') || ':' || COALESCE(p_event->>'timestamp', ''))::uuid
  );
  INSERT INTO cefflo_content_engine.content_engine_events (
    event_id, run_id, workflow_name, stage, status, retry_count,
    error_code, error_message, payload, created_at
  ) VALUES (
    new_id, NULLIF(p_event->>'run_id', '')::uuid, p_event->>'workflow_name',
    p_event->>'stage', p_event->>'status', COALESCE((p_event->>'retry_count')::integer, 0),
    p_event->>'error_code', p_event->>'error_message', p_event->'payload',
    COALESCE((p_event->>'created_at')::timestamptz, (p_event->>'timestamp')::timestamptz, now())
  ) ON CONFLICT (event_id) DO NOTHING;
  RETURN new_id;
END;
$$;

COMMIT;
