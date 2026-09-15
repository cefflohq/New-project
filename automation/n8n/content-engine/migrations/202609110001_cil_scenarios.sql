-- Creative Intelligence Layer (CIL) scenario storage.
-- Source doctrine: docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md
-- Phase 4 (Scenario Contract) / Phase 8 (Marketing Memory feedback contract).
-- Additive to 202609100001_content_engine_roi.sql -- does not modify n8n's internal
-- tables, does not modify any existing cefflo_content_engine table.

BEGIN;

CREATE TABLE IF NOT EXISTS cefflo_content_engine.cil_scenarios (
  scenario_id TEXT PRIMARY KEY CHECK (scenario_id ~ '^CIL-[0-9]{4,}$'),
  run_id UUID NULL REFERENCES cefflo_content_engine.content_engine_runs(run_id) ON DELETE SET NULL,
  master_concept_id TEXT NULL REFERENCES cefflo_content_engine.master_concepts(master_concept_id) ON DELETE SET NULL,
  business_archetype JSONB NOT NULL,
  order_profile JSONB NOT NULL,
  delivery_team JSONB NOT NULL,
  vehicle_mix JSONB NOT NULL,
  personas JSONB NOT NULL DEFAULT '[]'::jsonb,
  operational_problem JSONB NOT NULL,
  emotional_tension JSONB NOT NULL DEFAULT '[]'::jsonb,
  cefflo_relevance JSONB NOT NULL DEFAULT '[]'::jsonb,
  language_context JSONB NOT NULL DEFAULT '{}'::jsonb,
  novelty_signature JSONB NOT NULL,
  validation_status TEXT NOT NULL CHECK (validation_status IN ('PASS', 'REJECT', 'REVISE', 'HOLD')),
  validation_detail JSONB NOT NULL DEFAULT '{}'::jsonb,
  taxonomy_version TEXT NOT NULL DEFAULT '1.0',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS cil_scenarios_status_created_idx ON cefflo_content_engine.cil_scenarios(validation_status, created_at DESC);
CREATE INDEX IF NOT EXISTS cil_scenarios_master_concept_idx ON cefflo_content_engine.cil_scenarios(master_concept_id);

-- Diversity Engine support (§20): recent novelty signatures for duplicate detection,
-- scoped by business_type so the check stays cheap as history grows.
CREATE INDEX IF NOT EXISTS cil_scenarios_novelty_gin_idx ON cefflo_content_engine.cil_scenarios USING gin (novelty_signature);

COMMIT;
