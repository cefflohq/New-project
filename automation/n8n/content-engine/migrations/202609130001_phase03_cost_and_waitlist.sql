-- CEFFLO Phase 03 -- Batch 03K (cost telemetry) and Batch 03J (pre-launch waitlist).
-- Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §18-19, §23-25.
-- Additive to 202609100001_content_engine_roi.sql / 202609110001_cil_scenarios.sql --
-- does not modify any existing table, does not modify n8n's internal tables.
-- NOT APPLIED as part of this pass -- target Postgres instance remains unconfirmed
-- (same open item recorded against the DeepSeek AI Router Master's Phase 0 and D-29).

BEGIN;

-- §24-25: CPAC (Cost Per Accepted Content) / CPPC (Cost Per Published Content) telemetry.
-- One row per production attempt (video, design, or product-capture lane), whether
-- accepted or rejected, so cost-per-accepted/published can be computed honestly
-- (rejected attempts still cost money and must count in the denominator's numerator).
CREATE TABLE IF NOT EXISTS cefflo_content_engine.production_cost_log (
  attempt_id UUID PRIMARY KEY,
  scenario_id TEXT NOT NULL REFERENCES cefflo_content_engine.cil_scenarios(scenario_id) ON DELETE CASCADE,
  master_concept_id TEXT NULL REFERENCES cefflo_content_engine.master_concepts(master_concept_id) ON DELETE SET NULL,
  lane TEXT NOT NULL CHECK (lane IN ('video', 'design', 'product_capture')),
  provider TEXT NOT NULL,
  attempt_number INTEGER NOT NULL DEFAULT 1 CHECK (attempt_number >= 1),
  qa_status TEXT NOT NULL CHECK (qa_status IN ('PASS', 'REVISE', 'REJECT')),
  estimated_cost NUMERIC NOT NULL DEFAULT 0,
  actual_cost NUMERIC NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  accepted BOOLEAN NOT NULL DEFAULT FALSE,
  published BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS production_cost_log_scenario_idx ON cefflo_content_engine.production_cost_log(scenario_id, created_at DESC);
CREATE INDEX IF NOT EXISTS production_cost_log_accepted_idx ON cefflo_content_engine.production_cost_log(accepted, published);

-- CPAC / CPPC as a view, not a stored aggregate -- always recomputed from raw cost log rows
-- so it stays correct as pricing/providers change (matches 07_MARKETING_MEMORY.md's
-- "preserve raw metrics so historical scores can be recalculated" principle).
CREATE OR REPLACE VIEW cefflo_content_engine.production_cost_summary AS
SELECT
  lane,
  provider,
  count(*) AS total_attempts,
  count(*) FILTER (WHERE accepted) AS accepted_count,
  count(*) FILTER (WHERE published) AS published_count,
  sum(coalesce(actual_cost, estimated_cost)) AS total_cost,
  CASE WHEN count(*) FILTER (WHERE accepted) > 0
    THEN sum(coalesce(actual_cost, estimated_cost)) / count(*) FILTER (WHERE accepted)
    ELSE NULL END AS cpac,
  CASE WHEN count(*) FILTER (WHERE published) > 0
    THEN sum(coalesce(actual_cost, estimated_cost)) / count(*) FILTER (WHERE published)
    ELSE NULL END AS cppc
FROM cefflo_content_engine.production_cost_log
GROUP BY lane, provider;

-- §25 Budget Guardrails: one row per day/provider, checked before expensive production
-- is allowed to proceed. Spend enforcement itself is application/workflow logic, not
-- a database trigger -- this table is the source of truth it reads.
CREATE TABLE IF NOT EXISTS cefflo_content_engine.budget_guardrails (
  provider TEXT PRIMARY KEY,
  daily_video_generation_cap INTEGER NOT NULL DEFAULT 0,
  daily_spend_cap NUMERIC NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 1,
  max_candidates_to_production INTEGER NOT NULL DEFAULT 0,
  publishing_cap_per_day INTEGER NOT NULL DEFAULT 0,
  provider_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Seeded row for Seedance, disabled by default -- enabling requires a Founder Gate
-- decision (§38 item 2), not a migration.
INSERT INTO cefflo_content_engine.budget_guardrails (provider, daily_video_generation_cap, daily_spend_cap, max_retries, max_candidates_to_production, publishing_cap_per_day, provider_enabled)
VALUES ('seedance', 0, 0, 1, 0, 0, FALSE)
ON CONFLICT (provider) DO NOTHING;

-- §18-19: Pre-launch waitlist. Minimal fields, privacy-conscious, per the CEFFLO
-- Website SOT's Phase 03 scope (docs/cefflo/sot/11_CEFFLO_WEBSITE.md).
CREATE TABLE IF NOT EXISTS cefflo_content_engine.prelaunch_waitlist (
  waitlist_id UUID PRIMARY KEY,
  name TEXT NULL,
  business_name TEXT NULL,
  contact_email TEXT NULL,
  contact_phone TEXT NULL,
  business_type TEXT NULL,
  approximate_delivery_volume TEXT NULL,
  preferred_contact TEXT NULL CHECK (preferred_contact IS NULL OR preferred_contact IN ('email', 'phone', 'whatsapp')),
  source_platform TEXT NULL,
  campaign_content_id TEXT NULL,
  consent_given BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (contact_email IS NOT NULL OR contact_phone IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS prelaunch_waitlist_created_idx ON cefflo_content_engine.prelaunch_waitlist(created_at DESC);
CREATE INDEX IF NOT EXISTS prelaunch_waitlist_campaign_idx ON cefflo_content_engine.prelaunch_waitlist(campaign_content_id);

COMMIT;
