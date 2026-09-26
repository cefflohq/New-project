// CEFFLO Phase 03 -- Batches 03D/03E/03G/03I/03L acceptance tests.
// Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §33-36.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { loadTaxonomy, buildScenario } from '../scripts/cil-scenario-engine.mjs';
import { buildContentPackage } from '../scripts/content-script-engine.mjs';
import { preProductionQA, postProductionQA } from '../scripts/qa-engine.mjs';
import { submitVideoJob, pollVideoJob, generateWithRetryPolicy, VIDEO_PROVIDER_PRIMARY } from '../scripts/seedance-adapter.mjs';
import { nextState, canPublish, STATES } from '../scripts/approval-state-machine.mjs';
import { runDryRunBatch } from '../scripts/dry-run-batch.mjs';

const taxonomy = loadTaxonomy();

const baseInput = {
  business_archetype: { business_type: 'meal_prep', scale: 'small_team', daily_order_volume: 50, delivery_window: 'lunch' },
  archetype_category: 'food_and_meal_operations',
  order_profile: { count: 50, delivery_window: 'lunch', characteristics: ['multi_drop'] },
  delivery_team: { expected: 3, available: 3 },
  vehicle_mix: [{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }],
  trigger: { type: 'delivery_person_unavailable' },
  operational_problem: { primary: 'workload_redistribution' },
  personas: ['owner_founder', 'delivery_person'],
  human_behaviour: ['owner_reviews_orders'],
  emotional_tension: ['urgency'],
  cefflo_relevance: ['delivery_planning', 'rider_assignment'],
  desired_outcome: ['clearer_delivery_plan'],
  creative_opportunities: ['pov_owner'],
  language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
};

// --- contract schema is valid JSON and content packages satisfy its required fields ---
{
  const schema = JSON.parse(fs.readFileSync(path.join(import.meta.dirname, '../contracts/content-package.schema.json'), 'utf8'));
  const scenario = buildScenario(baseInput, taxonomy);
  const pkg = buildContentPackage(scenario, taxonomy);
  for (const key of schema.required) assert(key in pkg, `content package missing required contract field: ${key}`);
}

// --- Batch 03D: Content & Script Engine ---------------------------------
{
  const scenario = buildScenario(baseInput, taxonomy);
  const pkg = buildContentPackage(scenario, taxonomy);
  assert(pkg.hook.hook_bm.length > 0, 'hook must be generated');
  assert.equal(pkg.generation_provider, 'deterministic', 'default path must be deterministic, not a live LLM call, per §9');
  assert.equal(pkg.generation_cost, 0);
  assert.equal(pkg.platform_packages.length, 3, 'must produce meta/tiktok/threads lanes');
  assert.deepEqual(pkg.platform_packages.map((p) => p.lane), ['meta', 'tiktok', 'threads']);
  // mixed fleet -> workforce label must be "Delivery Team", not a singular Rider/Driver (D-27/D-29).
  assert(pkg.script.problem_beat.toLowerCase().includes('delivery team'));
  // §7: never a literal English translation artifact -- spot check no English filler leaked into BM hook.
  assert(!/\btransform\b|\bseamless\b|\brevolutioni[sz]e\b/i.test(pkg.hook.hook_bm));
}

// --- Batch 03E: Pre-/Post-Production QA ----------------------------------
{
  const scenario = buildScenario(baseInput, taxonomy);
  const pkg = buildContentPackage(scenario, taxonomy);
  const pre = preProductionQA(scenario, pkg, taxonomy, []);
  assert.equal(pre.status, 'PASS');

  const badPkg = { ...pkg, hook: { ...pkg.hook, hook_bm: 'Transform your delivery operations seamlessly.' } };
  const preBad = preProductionQA(scenario, badPkg, taxonomy, []);
  assert.equal(preBad.status, 'REJECT');
  assert(preBad.failed_checks.includes('generic_hook'));

  const dupPre = preProductionQA(scenario, pkg, taxonomy, [pkg.hook.hook_bm]);
  assert.equal(dupPre.status, 'REJECT');
  assert(dupPre.failed_checks.includes('insufficiently_distinct_from_recent_output'));

  const goodAsset = { lane: 'video', provider: VIDEO_PROVIDER_PRIMARY, vehicles_shown: ['motorcycle', 'car'], is_ai_generated_ui: false, qa_flags: [], claims: ['delivery_planning'] };
  const post = postProductionQA(goodAsset, scenario);
  assert.equal(post.status, 'PASS');

  const fakeUiAsset = { ...goodAsset, is_ai_generated_ui: true };
  const postFake = postProductionQA(fakeUiAsset, scenario);
  assert.equal(postFake.status, 'REJECT');
  assert(postFake.failed_checks.includes('ai_generated_product_ui_not_allowed'), '§10.4/§13: AI-generated fake product UI must hard-reject');

  const badClaimAsset = { ...goodAsset, claims: ['ai_route_optimization'] };
  const postBadClaim = postProductionQA(badClaimAsset, scenario);
  assert.equal(postBadClaim.status, 'REJECT');
}

// --- Batch 03G: Seedance adapter (stub mode only) -------------------------
{
  const scenario = buildScenario(baseInput, taxonomy);
  const pkg = buildContentPackage(scenario, taxonomy);
  assert.throws(() => submitVideoJob(scenario, pkg, { mode: 'live' }), /ERROR_SEEDANCE/, 'live Seedance calls must be blocked in Phase 03 (Founder Gate 2 not granted)');

  const job = submitVideoJob(scenario, pkg, { mode: 'stub' });
  assert.equal(job.provider, 'seedance');
  assert.equal(job.status, 'SUBMITTED');
  assert.equal(job.estimated_cost, 0);

  const resolved = pollVideoJob(job, scenario);
  assert.equal(resolved.status, 'COMPLETED');
  assert.equal(resolved.actual_cost, 0);

  const result = generateWithRetryPolicy(scenario, pkg, postProductionQA, { mode: 'stub' });
  assert.equal(result.status, 'ACCEPTED');
  assert(result.attempts.length >= 1);
  assert.equal(result.total_cost, 0);
}

// --- Batch 03I: Approval state machine -------------------------------------
{
  assert.equal(nextState('DRAFT', 'QA_PASS'), 'QA_PASS');
  assert.equal(nextState('QA_PASS', 'FOUNDER_REVIEW'), 'FOUNDER_REVIEW');
  assert.equal(nextState('FOUNDER_REVIEW', 'APPROVED'), 'APPROVED');
  assert.throws(() => nextState('DRAFT', 'PUBLISHED'), /ERROR_VALIDATION/, 'must never allow DRAFT -> PUBLISHED directly, bypassing Founder approval');
  assert.throws(() => nextState('FOUNDER_REVIEW', 'PUBLISHED'), /ERROR_VALIDATION/);
  assert.equal(canPublish('APPROVED', 'APPROVE'), true);
  assert.equal(canPublish('FOUNDER_REVIEW', 'APPROVE'), false, 'FOUNDER_REVIEW alone must never authorize publish');
  assert.equal(canPublish('DRAFT', 'APPROVE'), false);
  assert(STATES.includes('REJECTED') && STATES.includes('HOLD') && STATES.includes('REVISE'));
}

// --- Batch 03L: Dry Run (§34: 30-50 candidates) ----------------------------
{
  const { summary, results } = runDryRunBatch(40);
  assert.equal(summary.total_candidates, 40);
  assert(summary.total_candidates >= 30 && summary.total_candidates <= 50, '§34 requires a 30-50 candidate batch');
  assert.equal(summary.total_cost, 0, 'dry run must be zero-cost (SAFE / NON-PUBLISHING MODE, §32)');
  assert(summary.unique_business_types >= 10, 'AC-03/§33: must not be food-only biased');
  assert.equal(summary.unique_vehicle_types_used, 3, '§33: must exercise motorcycle, car, and van -- no motorcycle-only bias');
  assert(summary.accepted > 0 && summary.rejected_or_revised > 0, 'a healthy dry run both accepts good candidates and rejects/revises bad ones -- 100% pass would mean the QA gates are not really filtering');
  // every accepted candidate must have passed through pre-production QA before an (even stubbed) production attempt was counted.
  for (const r of results.filter((x) => x.status === 'ACCEPTED')) {
    assert(r.production_attempts >= 1);
    assert.equal(r.approval_state, 'QA_PASS');
  }
}

console.log(JSON.stringify({ result: 'PASS', suites: ['content_script_engine', 'qa_engine', 'seedance_adapter_stub', 'approval_state_machine', 'dry_run_batch'] }, null, 2));
