// CEFFLO Phase 03 Batch 03L -- Dry Run.
// Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §20 Stage A,
// §34 (30-50 candidate concepts), §35 (limited Seedance pilot), §36 (end-to-end flow).
// SAFE / NON-PUBLISHING MODE throughout (§32): no live LLM call, no live Seedance
// call, no publish, no waitlist write -- every provider is the deterministic stub.
// Deterministic (not random) scenario construction, so results are reproducible.
import { loadTaxonomy, buildScenario } from './cil-scenario-engine.mjs';
import { validateScenario } from './cil-validate.mjs';
import { buildContentPackage } from './content-script-engine.mjs';
import { preProductionQA, postProductionQA } from './qa-engine.mjs';
import { generateWithRetryPolicy } from './seedance-adapter.mjs';
import { nextState } from './approval-state-machine.mjs';

const VEHICLE_MIX_ROTATION = [
  [{ type: 'motorcycle', count: 3 }],
  [{ type: 'car', count: 2 }],
  [{ type: 'van', count: 1 }],
  [{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }],
  [{ type: 'motorcycle', count: 1 }, { type: 'van', count: 1 }],
  [{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }, { type: 'van', count: 1 }],
];

const TRIGGER_ROTATION = [
  { type: 'sudden_order_spike', problem: 'order_intake_chaos' },
  { type: 'delivery_person_unavailable', problem: 'workload_redistribution' },
  { type: 'too_many_drops', problem: 'planning_pressure' },
  { type: 'order_status_question', problem: 'customer_communication' },
];

function buildScenarioInput(archetypeCategory, businessType, index, taxonomy) {
  const vehicleMix = VEHICLE_MIX_ROTATION[index % VEHICLE_MIX_ROTATION.length];
  const trigger = TRIGGER_ROTATION[index % TRIGGER_ROTATION.length];
  const orderCount = 20 + (index * 7) % 90;
  return {
    business_archetype: { business_type: businessType, scale: index % 3 === 0 ? 'larger_operation' : 'small_team', daily_order_volume: orderCount, delivery_window: 'lunch' },
    archetype_category: archetypeCategory,
    order_profile: { count: orderCount, delivery_window: 'lunch', characteristics: ['multi_drop'] },
    delivery_team: { expected: vehicleMix.reduce((s, v) => s + v.count, 0), available: Math.max(1, vehicleMix.reduce((s, v) => s + v.count, 0) - (index % 2)) },
    vehicle_mix: vehicleMix,
    trigger: { type: trigger.type },
    operational_problem: { primary: trigger.problem },
    personas: ['owner_founder', 'delivery_person'],
    human_behaviour: ['owner_reviews_orders'],
    emotional_tension: ['urgency'],
    cefflo_relevance: ['delivery_planning', 'rider_assignment'],
    desired_outcome: ['clearer_delivery_plan'],
    creative_opportunities: ['pov_owner'],
    language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
  };
}

export function runDryRunBatch(count = 40) {
  const taxonomy = loadTaxonomy();
  const archetypes = taxonomy.businessArchetypes.categories.flatMap((c) => c.archetypes.map((a) => [c.category, a]));
  const results = [];
  const recentSignatures = [];
  const recentHooks = [];

  for (let i = 0; i < count; i += 1) {
    const [category, businessType] = archetypes[i % archetypes.length];
    const input = buildScenarioInput(category, businessType, i, taxonomy);
    const scenario = buildScenario(input, taxonomy);
    const scenarioValidation = validateScenario(scenario, taxonomy, recentSignatures);

    if (scenarioValidation.status !== 'PASS') {
      results.push({ scenario_id: scenario.scenario_id, business_type: businessType, vehicle_mix: scenario.vehicle_mix.map((v) => v.type), stage_reached: 'scenario_validation', status: scenarioValidation.status, failed_checks: scenarioValidation.failed_checks });
      continue;
    }
    recentSignatures.push(scenario.novelty_signature);

    const contentPackage = buildContentPackage(scenario, taxonomy);
    const preQA = preProductionQA(scenario, contentPackage, taxonomy, recentHooks);
    if (preQA.status !== 'PASS') {
      results.push({ scenario_id: scenario.scenario_id, business_type: businessType, vehicle_mix: scenario.vehicle_mix.map((v) => v.type), stage_reached: 'pre_production_qa', status: preQA.status, failed_checks: preQA.failed_checks });
      continue;
    }
    recentHooks.push(contentPackage.hook.hook_bm);

    const production = generateWithRetryPolicy(scenario, contentPackage, postProductionQA, { mode: 'stub' });
    const approvalState = production.status === 'ACCEPTED' ? nextState('DRAFT', 'QA_PASS') : null;

    results.push({
      scenario_id: scenario.scenario_id,
      business_type: businessType,
      vehicle_mix: scenario.vehicle_mix.map((v) => v.type),
      hook_family: contentPackage.hook.hook_family,
      hook_bm: contentPackage.hook.hook_bm,
      stage_reached: 'production',
      status: production.status,
      production_attempts: production.attempts.length,
      total_cost: production.total_cost,
      approval_state: approvalState,
    });
  }

  const accepted = results.filter((r) => r.status === 'ACCEPTED');
  const businessTypeDiversity = new Set(results.map((r) => r.business_type)).size;
  const vehicleDiversity = new Set(results.flatMap((r) => r.vehicle_mix || [])).size;
  const summary = {
    total_candidates: results.length,
    accepted: accepted.length,
    rejected_or_revised: results.length - accepted.length,
    pass_rate: Number((accepted.length / results.length).toFixed(2)),
    unique_business_types: businessTypeDiversity,
    unique_vehicle_types_used: vehicleDiversity,
    total_retry_attempts: results.reduce((s, r) => s + (r.production_attempts || 0), 0),
    total_cost: results.reduce((s, r) => s + (r.total_cost || 0), 0),
    mode: 'SAFE_NON_PUBLISHING_DRY_RUN',
  };
  return { summary, results };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const count = Number(process.argv[2] || 40);
  const { summary, results } = runDryRunBatch(count);
  console.log(JSON.stringify({ summary, sample_results: results.slice(0, 5) }, null, 2));
}
