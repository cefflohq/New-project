\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF to_regclass('cefflo_content_engine.content_engine_runs') IS NULL
     OR to_regclass('cefflo_content_engine.marketing_memory') IS NULL
     OR to_regclass('cefflo_content_engine.content_engine_events') IS NULL THEN
    RAISE EXCEPTION 'required Content Engine tables are missing';
  END IF;
END;
$$;

INSERT INTO cefflo_content_engine.content_engine_runs VALUES (
  '00000000-0000-4000-8000-000000000001',
  '00000000-0000-4000-8000-000000000002', NULL,
  'ROI architecture smoke test', 'Malaysia', 'English', 'NEW', 1, 0,
  '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z'
);

INSERT INTO cefflo_content_engine.content_angles VALUES (
  'angle-roi-001', '00000000-0000-4000-8000-000000000001',
  'Local delivery operational clarity', 'Local business operator',
  'Multiple local orders become hard to coordinate',
  'Turn scattered delivery activity into one visible operating flow',
  'Show the operational contrast', 90, 0,
  '[{"source":"docs/cefflo/sot/01_PRODUCT_TRUTH.md"}]', TRUE,
  '2026-09-10T00:00:00Z'
);

INSERT INTO cefflo_content_engine.master_concepts VALUES (
  'CEFFLO-2026-W37-E001', '00000000-0000-4000-8000-000000000001', 'angle-roi-001',
  'Cefflo helps operators see today''s local delivery operation.',
  'Multiple local orders become hard to coordinate',
  'The problem is operational visibility',
  'Orders, coverage, zones, planning, runs and completion',
  '[]', 'Show the operational contrast', 'See the operating flow',
  'Use real UI only', '[]', '[]',
  '[{"source":"docs/cefflo/sot/01_PRODUCT_TRUTH.md"}]',
  'CONCEPT_READY', '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z'
);

INSERT INTO cefflo_content_engine.creative_packages
SELECT ('00000000-0000-4000-8000-00000000001' || n)::uuid,
       'CEFFLO-2026-W37-E001', lane, destinations::jsonb,
       jsonb_build_object('lane', lane), 'PASS', 0, 'QA_PENDING',
       '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z'
FROM (VALUES
  (1, 'meta', '["instagram","facebook"]'),
  (2, 'tiktok', '["tiktok"]'),
  (3, 'threads', '["threads"]')
) AS x(n, lane, destinations);

INSERT INTO cefflo_content_engine.founder_reviews VALUES (
  '00000000-0000-4000-8000-000000000020', 'CEFFLO-2026-W37-E001',
  'APPROVE', 'ROI fixture', NULL, '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z'
);

INSERT INTO cefflo_content_engine.publish_records
SELECT ('00000000-0000-4000-8000-00000000003' || n)::uuid,
       'CEFFLO-2026-W37-E001-' || platform,
       'CEFFLO-2026-W37-E001', platform, NULL, NULL, 'STUBBED', NULL, NULL,
       '{"provider_mode":"stub","external_call":false}',
       '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z'
FROM (VALUES (1, 'instagram'), (2, 'facebook'), (3, 'tiktok'), (4, 'threads')) AS x(n, platform)
ON CONFLICT (master_concept_id, platform) DO NOTHING;

INSERT INTO cefflo_content_engine.publish_records
SELECT ('00000000-0000-4000-8000-00000000004' || n)::uuid,
       'CEFFLO-2026-W37-E001-' || platform,
       'CEFFLO-2026-W37-E001', platform, NULL, NULL, 'STUBBED', NULL, NULL,
       '{}', '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z'
FROM (VALUES (1, 'instagram'), (2, 'facebook'), (3, 'tiktok'), (4, 'threads')) AS x(n, platform)
ON CONFLICT (master_concept_id, platform) DO NOTHING;

INSERT INTO cefflo_content_engine.content_analytics
SELECT ('00000000-0000-4000-8000-00000000005' || n)::uuid,
       'CEFFLO-2026-W37-E001-' || platform, platform,
       '{"views":0,"reach":0,"provider_mode":"stub"}', score,
       '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z'
FROM (VALUES (1, 'instagram', 72), (2, 'facebook', 68), (3, 'tiktok', 75), (4, 'threads', 64)) AS x(n, platform, score);

SELECT cefflo_content_engine.persist_marketing_memory(jsonb_build_object(
  'marketing_memory_records', jsonb_agg(jsonb_build_object(
    'content_id', 'CEFFLO-2026-W37-E001-' || platform,
    'master_concept_id', 'CEFFLO-2026-W37-E001',
    'angle', 'Turn scattered delivery activity into one visible operating flow',
    'hook', 'Local delivery gets harder when orders multiply',
    'audience', 'Local business operator', 'platform', platform, 'format', format,
    'performance_score', score, 'qa_feedback', '[]'::jsonb,
    'founder_feedback', 'ROI fixture', 'lessons', '[]'::jsonb,
    'created_at', '2026-09-10T00:00:00Z', 'updated_at', '2026-09-10T00:00:00Z'
  ))
))
FROM (VALUES
  ('instagram', 'reel', 72), ('facebook', 'reel', 68),
  ('tiktok', 'short_form_video', 75), ('threads', 'text_post', 64)
) AS x(platform, format, score);

SELECT cefflo_content_engine.log_event('{"event_id":"00000000-0000-4000-8000-000000000070","run_id":"00000000-0000-4000-8000-000000000001","workflow_name":"CEFFLO - 99 - Error & Recovery","stage":"SOT_RETRIEVAL","status":"ERROR","retry_count":0,"error_code":"ERROR_SOT","error_message":"fixture source missing","payload":{"manual_recovery":true},"timestamp":"2026-09-10T00:00:00Z"}'::jsonb);

DO $$
DECLARE
  publish_count INTEGER;
  memory_count INTEGER;
  event_count INTEGER;
BEGIN
  SELECT count(*) INTO publish_count FROM cefflo_content_engine.publish_records WHERE master_concept_id = 'CEFFLO-2026-W37-E001';
  SELECT count(*) INTO memory_count FROM cefflo_content_engine.marketing_memory WHERE master_concept_id = 'CEFFLO-2026-W37-E001';
  SELECT count(*) INTO event_count FROM cefflo_content_engine.content_engine_events WHERE run_id = '00000000-0000-4000-8000-000000000001';
  IF publish_count <> 4 THEN RAISE EXCEPTION 'publisher idempotency failed: %', publish_count; END IF;
  IF memory_count <> 4 THEN RAISE EXCEPTION 'marketing memory persistence failed: %', memory_count; END IF;
  IF event_count <> 1 THEN RAISE EXCEPTION 'event persistence failed: %', event_count; END IF;
END;
$$;

ROLLBACK;
SELECT 'DB_SMOKE_PASS' AS result;
