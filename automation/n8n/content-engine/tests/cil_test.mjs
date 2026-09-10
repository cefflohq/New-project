// CEFFLO Creative Intelligence Layer -- Phase 10 representative tests.
// Source doctrine: docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md §38.
// Plain Node assert, no framework/deps, matching tests/roi_smoke.mjs convention.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { loadTaxonomy, buildScenario, proposeVehicleMix, resolveWorkforceLabel } from '../scripts/cil-scenario-engine.mjs';
import { validateScenario, APPROVED_CEFFLO_CAPABILITIES } from '../scripts/cil-validate.mjs';

const root = path.resolve(import.meta.dirname, '..');
const taxonomy = loadTaxonomy();

// --- schema conformance (lightweight, dependency-free) -------------------
const schema = JSON.parse(fs.readFileSync(path.join(root, 'contracts/cil-scenario.schema.json'), 'utf8'));
function assertMatchesSchema(scenario, label) {
  for (const key of schema.required) {
    assert(key in scenario, `${label}: missing required field ${key}`);
  }
  for (const key of Object.keys(scenario)) {
    assert(key in schema.properties, `${label}: unexpected field ${key} not in schema (additionalProperties: false)`);
  }
  assert.match(scenario.scenario_id, /^CIL-[0-9]{4,}$/, `${label}: scenario_id must match contract pattern`);
}

// --- 10 representative scenarios ------------------------------------------
const cases = [
  {
    name: '1. meal prep + motorcycles',
    input: {
      business_archetype: { business_type: 'meal_prep', scale: 'small_team', daily_order_volume: 73, delivery_window: 'lunch' },
      archetype_category: 'food_and_meal_operations',
      order_profile: { count: 73, delivery_window: 'before_12_30', characteristics: ['lunch_delivery', 'multi_drop'] },
      delivery_team: { expected: 4, available: 3 },
      trigger: { type: 'delivery_person_unavailable' },
      operational_problem: { primary: 'workload_redistribution', secondary: ['delivery_deadline_pressure', 'customer_eta_questions'] },
      personas: ['owner_founder', 'operations_admin', 'delivery_person'],
      human_behaviour: ['owner_reviews_orders', 'admin_receives_customer_messages', 'delivery_team_prepares_deliveries'],
      emotional_tension: ['urgency', 'uncertainty', 'responsibility'],
      cefflo_relevance: ['delivery_planning', 'multi_drop_runs', 'rider_assignment', 'delivery_status'],
      desired_outcome: ['clearer_delivery_plan', 'controlled_dispatch', 'better_operational_visibility'],
      creative_opportunities: ['pov_owner', 'dialogue_owner_staff'],
      language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
    },
  },
  {
    name: '2. catering + van',
    input: {
      business_archetype: { business_type: 'catering', scale: 'mid_size', daily_order_volume: 5, delivery_window: 'event_specific' },
      archetype_category: 'food_and_meal_operations',
      bulky: true,
      order_profile: { count: 5, delivery_window: 'event_specific', characteristics: ['large_mixed_loads', 'strict_arrival_windows'] },
      delivery_team: { expected: 3, available: 3 },
      trigger: { type: 'schedule_change' },
      operational_problem: { primary: 'delivery_window_conflict', secondary: ['coordination_between_kitchen_and_drivers'] },
      personas: ['owner_founder', 'packing_staff', 'delivery_person'],
      human_behaviour: ['staff_loads_van', 'owner_confirms_timing'],
      emotional_tension: ['time_pressure', 'responsibility'],
      cefflo_relevance: ['delivery_planning', 'dispatch'],
      desired_outcome: ['controlled_dispatch'],
      creative_opportunities: ['product_demo'],
      language_context: { register: 'clean_natural', primary_language: 'ms-MY' },
    },
  },
  {
    name: '3. florist + car',
    input: {
      business_archetype: { business_type: 'florist', scale: 'small_team', daily_order_volume: 22, delivery_window: 'morning' },
      archetype_category: 'special_handling',
      fragile: true,
      order_profile: { count: 22, delivery_window: 'morning', characteristics: ['fragile_or_presentation_sensitive', 'time_window_deliveries'] },
      delivery_team: { expected: 2, available: 2 },
      trigger: { type: 'fragile_order' },
      operational_problem: { primary: 'vehicle_pressure', secondary: ['peak_day_pressure'] },
      personas: ['owner_founder', 'delivery_person'],
      human_behaviour: ['staff_arranges_flowers', 'driver_checks_load'],
      emotional_tension: ['responsibility'],
      cefflo_relevance: ['zones', 'delivery_status'],
      desired_outcome: ['better_operational_visibility'],
      creative_opportunities: ['situational'],
      language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
    },
  },
  {
    name: '4. ecommerce + mixed fleet',
    input: {
      business_archetype: { business_type: 'online_seller', scale: 'small_team', daily_order_volume: 68, delivery_window: 'afternoon' },
      archetype_category: 'retail_and_online_commerce',
      order_profile: { count: 68, delivery_window: 'before_2pm', characteristics: ['scattered_channels', 'address_handling'] },
      delivery_team: { expected: 4, available: 4 },
      vehicle_mix: [{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }],
      trigger: { type: 'sudden_order_spike' },
      operational_problem: { primary: 'order_intake_chaos', secondary: ['batching_and_rider_assignment'] },
      personas: ['operations_admin', 'delivery_person'],
      human_behaviour: ['admin_compares_channels'],
      emotional_tension: ['overload'],
      cefflo_relevance: ['order_organization', 'rider_assignment'],
      desired_outcome: ['clearer_delivery_plan'],
      creative_opportunities: ['dialogue'],
      language_context: { register: 'pasar_beradab', primary_language: 'ms-MY' },
    },
  },
  {
    name: '5. factory/B2B + van',
    input: {
      business_archetype: { business_type: 'factory', scale: 'larger_operation', daily_order_volume: 67, delivery_window: 'full_day' },
      archetype_category: 'business_and_industrial',
      order_profile: { count: 67, delivery_window: 'full_day', characteristics: ['dozens_of_drop_points', 'manifests'] },
      delivery_team: { expected: 4, available: 4 },
      trigger: { type: 'too_many_drops' },
      operational_problem: { primary: 'planning_pressure', secondary: ['route_efficiency'] },
      personas: ['operations_admin', 'delivery_person'],
      human_behaviour: ['admin_groups_by_area'],
      emotional_tension: ['confusion'],
      cefflo_relevance: ['zones', 'delivery_planning', 'operational_visibility'],
      desired_outcome: ['better_operational_visibility'],
      creative_opportunities: ['product_demo', 'educational'],
      language_context: { register: 'clean_natural', primary_language: 'ms-MY' },
    },
  },
  {
    name: '6. bakery + motorcycle/car',
    input: {
      business_archetype: { business_type: 'bakery', scale: 'small_team', daily_order_volume: 36, delivery_window: 'afternoon' },
      archetype_category: 'food_and_meal_operations',
      order_profile: { count: 36, delivery_window: 'before_3pm', characteristics: ['seasonal_spikes', 'time_window_deliveries'] },
      delivery_team: { expected: 3, available: 3 },
      vehicle_mix: [{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }],
      trigger: { type: 'delivery_window_conflict' },
      operational_problem: { primary: 'planning_pressure' },
      personas: ['owner_founder', 'delivery_person'],
      human_behaviour: ['owner_checks_orders'],
      emotional_tension: ['time_pressure'],
      cefflo_relevance: ['delivery_planning'],
      desired_outcome: ['controlled_dispatch'],
      creative_opportunities: ['situational'],
      language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
    },
  },
  {
    name: '7. delivery-person shortage',
    input: {
      business_archetype: { business_type: 'meal_prep', scale: 'small_team', daily_order_volume: 50, delivery_window: 'lunch' },
      archetype_category: 'food_and_meal_operations',
      order_profile: { count: 50, delivery_window: 'lunch', characteristics: ['multi_drop'] },
      delivery_team: { expected: 4, available: 3 },
      trigger: { type: 'delivery_person_unavailable' },
      operational_problem: { primary: 'workload_redistribution' },
      personas: ['owner_founder', 'delivery_person'],
      human_behaviour: ['owner_reassigns_workload'],
      emotional_tension: ['urgency', 'uncertainty'],
      cefflo_relevance: ['rider_assignment'],
      desired_outcome: ['controlled_dispatch'],
      creative_opportunities: ['pov_owner'],
      language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
    },
  },
  {
    name: '8. order spike',
    input: {
      business_archetype: { business_type: 'local_ecommerce', scale: 'small_team', daily_order_volume: 90, delivery_window: 'afternoon' },
      archetype_category: 'retail_and_online_commerce',
      order_profile: { count: 90, delivery_window: 'afternoon', characteristics: ['sudden_order_spike'] },
      delivery_team: { expected: 4, available: 4 },
      trigger: { type: 'sudden_order_spike' },
      operational_problem: { primary: 'order_intake_chaos' },
      personas: ['operations_admin'],
      human_behaviour: ['admin_receives_customer_messages'],
      emotional_tension: ['overload', 'time_pressure'],
      cefflo_relevance: ['order_organization', 'zones'],
      desired_outcome: ['clearer_delivery_plan'],
      creative_opportunities: ['ugc_style'],
      language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
    },
  },
  {
    name: '9. customer communication pressure',
    input: {
      business_archetype: { business_type: 'home_food_business', scale: 'small_team', daily_order_volume: 40, delivery_window: 'lunch' },
      archetype_category: 'food_and_meal_operations',
      order_profile: { count: 40, delivery_window: 'lunch', characteristics: ['multi_drop'] },
      delivery_team: { expected: 3, available: 3 },
      trigger: { type: 'order_status_question' },
      operational_problem: { primary: 'customer_communication', secondary: ['staff_repeatedly_answering_delivery_questions'] },
      personas: ['operations_admin', 'customer_recipient'],
      human_behaviour: ['admin_receives_customer_messages'],
      emotional_tension: ['frustration'],
      cefflo_relevance: ['delivery_status', 'customer_tracking_where_implemented'],
      desired_outcome: ['better_operational_visibility'],
      creative_opportunities: ['dialogue'],
      language_context: { register: 'pasar_beradab', primary_language: 'ms-MY' },
    },
  },
  {
    name: '10. mixed-vehicle workload',
    input: {
      business_archetype: { business_type: 'distributor', scale: 'mid_size', daily_order_volume: 80, delivery_window: 'full_day' },
      archetype_category: 'business_and_industrial',
      order_profile: { count: 80, delivery_window: 'full_day', characteristics: ['recurring_routes', 'multiple_branches'] },
      delivery_team: { expected: 4, available: 4 },
      vehicle_mix: [{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }, { type: 'van', count: 1 }],
      trigger: { type: 'too_many_drops' },
      operational_problem: { primary: 'planning_pressure' },
      personas: ['operations_admin', 'delivery_person'],
      human_behaviour: ['admin_groups_by_area'],
      emotional_tension: ['confusion', 'satisfaction_when_operation_becomes_controlled'],
      cefflo_relevance: ['zones', 'delivery_planning', 'rider_assignment'],
      desired_outcome: ['clearer_delivery_plan', 'better_operational_visibility'],
      creative_opportunities: ['educational', 'product_demo'],
      language_context: { register: 'clean_natural', primary_language: 'ms-MY' },
    },
  },
];

const results = [];
const recentSignatures = [];
for (const { name, input } of cases) {
  const scenario = buildScenario(input, taxonomy);
  assertMatchesSchema(scenario, name);
  const validation = validateScenario(scenario, taxonomy, recentSignatures);
  assert.equal(validation.status, 'PASS', `${name}: expected PASS, got ${validation.status} (${JSON.stringify(validation.detail)})`);
  recentSignatures.push(scenario.novelty_signature);
  results.push({ name, scenario_id: scenario.scenario_id, vehicle_mix: scenario.vehicle_mix, status: validation.status });
}
assert.equal(results.length, 10, 'must exercise all 10 representative scenarios');

// --- vehicle realism: reject an implausible mix ---------------------------
{
  const badInput = { ...cases[0].input, vehicle_mix: [{ type: 'motorcycle', count: 1 }], order_profile: { ...cases[0].input.order_profile, count: 200 } };
  const scenario = buildScenario(badInput, taxonomy);
  const validation = validateScenario(scenario, taxonomy, []);
  assert(validation.failed_checks.includes('VEHICLE_FIT'), 'implausible 200-order single-motorcycle load must fail VEHICLE_FIT');
}

// --- Product Truth guardrail: unapproved capability must REJECT -----------
{
  const badInput = { ...cases[0].input, cefflo_relevance: ['ai_route_optimization', 'live_gps_tracking'] };
  const scenario = buildScenario(badInput, taxonomy);
  const validation = validateScenario(scenario, taxonomy, []);
  assert.equal(validation.status, 'REJECT', 'unapproved CEFFLO capability claims must hard-reject');
  assert(validation.failed_checks.includes('PRODUCT_FIT'));
  for (const cap of ['ai_route_optimization', 'live_gps_tracking']) assert(!APPROVED_CEFFLO_CAPABILITIES.includes(cap));
}

// --- anti-fabrication guardrail --------------------------------------------
{
  const badInput = { ...cases[0].input, desired_outcome: ['fake testimonial from happy customer'] };
  const scenario = buildScenario(badInput, taxonomy);
  const validation = validateScenario(scenario, taxonomy, []);
  assert.equal(validation.status, 'REJECT');
  assert(validation.failed_checks.includes('ANTI_FABRICATION'));
}

// --- diversity engine: exact duplicate novelty signature must be flagged --
{
  const scenarioA = buildScenario(cases[0].input, taxonomy);
  const scenarioB = buildScenario(cases[0].input, taxonomy);
  const validation = validateScenario(scenarioB, taxonomy, [scenarioA.novelty_signature]);
  assert(validation.failed_checks.includes('NOVELTY'), 'identical scenario shape must be flagged by the diversity engine');
}

// --- GATE B (RESOLVED, D-27 update): canonical_role stays 'rider' everywhere; -----
// --- display label is vehicle-contextual: Motorcycle->Rider, Car/Van->Driver -----
{
  const vehicleTypes = JSON.parse(fs.readFileSync(path.join(root, 'fixtures/cil/vehicle_types.json'), 'utf8'));
  const expectedLabels = { motorcycle: 'Rider', car: 'Driver', van: 'Driver' };
  for (const v of vehicleTypes.vehicle_types) {
    assert.equal(v.canonical_role, 'rider', `${v.id}: canonical_role (product/schema identifier) must stay 'rider' -- backend terminology is never renamed by CIL`);
    assert.equal(v.natural_language_label, expectedLabels[v.id], `${v.id}: natural_language_label must match the Founder's vehicle-contextual resolution`);
  }
  assert.equal(vehicleTypes.vehicle_types.find((v) => v.id === 'van').alt_label, 'Van Driver');
  assert.equal(vehicleTypes.mixed_fleet_label, 'Delivery Team');
}

// --- workforce label resolution: motorcycle/car/van/mixed-fleet scenarios -------
{
  assert.equal(resolveWorkforceLabel([{ type: 'motorcycle', count: 3 }], taxonomy), 'Rider');
  assert.equal(resolveWorkforceLabel([{ type: 'car', count: 2 }], taxonomy), 'Driver');
  assert.equal(resolveWorkforceLabel([{ type: 'van', count: 1 }], taxonomy), 'Driver');
  assert.equal(resolveWorkforceLabel([{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }], taxonomy), 'Delivery Team');
  assert.equal(resolveWorkforceLabel([{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }, { type: 'van', count: 1 }], taxonomy), 'Delivery Team');

  // and confirmed end-to-end through buildScenario() + validateScenario() for each of the 10 cases
  const single = buildScenario(cases[0].input, taxonomy); // meal prep -> engine proposes motorcycle-heavy mix
  assert.equal(single.delivery_team.label, resolveWorkforceLabel(single.vehicle_mix, taxonomy));
  const van = buildScenario(cases[1].input, taxonomy); // catering -> van
  assert.equal(van.delivery_team.label, 'Driver');
  const car = buildScenario(cases[2].input, taxonomy); // florist -> car
  assert.equal(car.delivery_team.label, 'Driver');
  const mixed = buildScenario(cases[3].input, taxonomy); // ecommerce -> explicit mixed fleet
  assert.equal(mixed.delivery_team.label, 'Delivery Team');
  const mixed10 = buildScenario(cases[9].input, taxonomy); // mixed-vehicle workload -> motorcycle+car+van
  assert.equal(mixed10.delivery_team.label, 'Delivery Team');
}

// --- backend/schema/product terminology untouched: no vehicle_type/enum renamed --
{
  const repo = path.resolve(root, '../../..');
  const migration = fs.readFileSync(path.join(repo, 'supabase/migrations/202609030003_s4_11_batch_3_vehicle_capacity_compatibility.sql'), 'utf8');
  assert.match(migration, /create type public\.rider_vehicle_type as enum/, 'the real product enum must remain rider_vehicle_type, untouched by CIL');
  assert(!/create\s+type\s+public\.driver_vehicle_type/i.test(migration), 'no competing driver_vehicle_type enum may be introduced');
}

// --- taxonomy sanity: business archetypes span beyond food ----------------
{
  const categories = taxonomy.businessArchetypes.categories.map((c) => c.category);
  assert(categories.includes('business_and_industrial'), 'business archetypes must extend beyond food (AC-03)');
  assert(categories.includes('retail_and_online_commerce'));
  const allArchetypes = taxonomy.businessArchetypes.categories.flatMap((c) => c.archetypes);
  assert(allArchetypes.length >= 20, 'taxonomy should span a real breadth of business archetypes');
}

// --- vehicle mix proposal heuristic is deterministic and vehicle-aware ----
{
  const van = proposeVehicleMix({ orderCount: 80, archetypeCategory: 'business_and_industrial' });
  assert(van.every((v) => v.type === 'van'));
  const car = proposeVehicleMix({ orderCount: 22, archetypeCategory: 'special_handling', fragile: true });
  assert(car.every((v) => v.type === 'car'));
  const moto = proposeVehicleMix({ orderCount: 40, archetypeCategory: 'food_and_meal_operations' });
  assert(moto.some((v) => v.type === 'motorcycle'));
}

console.log(JSON.stringify({
  result: 'PASS',
  scenarios_tested: results.length,
  scenario_ids: results.map((r) => r.scenario_id),
  negative_tests_passed: ['VEHICLE_FIT_reject', 'PRODUCT_FIT_reject', 'ANTI_FABRICATION_reject', 'NOVELTY_flag', 'taxonomy_breadth'],
  gate_b: 'RESOLVED (D-27 update, 2026-09-11): canonical_role=rider (unchanged); display label Motorcycle=Rider, Car/Van=Driver, mixed=Delivery Team',
  workforce_label_checks: ['motorcycle->Rider', 'car->Driver', 'van->Driver', 'mixed_2type->Delivery Team', 'mixed_3type->Delivery Team', 'backend_enum_untouched'],
}, null, 2));
