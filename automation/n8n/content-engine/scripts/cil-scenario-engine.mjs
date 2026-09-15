// CEFFLO Creative Intelligence Layer -- deterministic scenario construction.
// Source doctrine: docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md §13 Scenario Engine.
// Deterministic on purpose (Phase 5): candidate construction is auditable/reproducible;
// only the downstream creative-writing stage should call an LLM.
import fs from 'node:fs';
import path from 'node:path';

const CIL_DIR = path.resolve(import.meta.dirname, '../fixtures/cil');

export function loadTaxonomy() {
  const read = (name) => JSON.parse(fs.readFileSync(path.join(CIL_DIR, name), 'utf8'));
  return {
    vehicleTypes: read('vehicle_types.json'),
    businessArchetypes: read('business_archetypes.json'),
    personas: read('personas.json'),
    operationalSituations: read('operational_situations.json'),
    emotionalTensions: read('emotional_tensions.json'),
    creativeFormats: read('creative_formats.json'),
  };
}

// Deterministic vehicle-mix heuristic per §4 Vehicle Realism Rule.
// Not an optimization model -- a plausibility heuristic for scenario construction only.
export function proposeVehicleMix({ orderCount, archetypeCategory, bulky = false, fragile = false }) {
  if (bulky || archetypeCategory === 'business_and_industrial') {
    const vans = Math.max(1, Math.ceil(orderCount / 60));
    return [{ type: 'van', count: vans }];
  }
  if (fragile || archetypeCategory === 'special_handling') {
    const cars = Math.max(1, Math.ceil(orderCount / 25));
    return [{ type: 'car', count: cars }];
  }
  // default: small dense drops favor motorcycles, with a car once volume crosses a threshold.
  const motorcycles = Math.max(1, Math.ceil(Math.min(orderCount, 60) / 25));
  const mix = [{ type: 'motorcycle', count: motorcycles }];
  if (orderCount > 60) mix.push({ type: 'car', count: Math.max(1, Math.ceil((orderCount - 60) / 30)) });
  return mix;
}

// GATE B resolution (docs/cefflo/05_DECISIONS.md D-27, 2026-09-11): vehicle-contextual
// DISPLAY label only. Motorcycle -> Rider, Car/Van -> Driver, mixed fleet -> Delivery Team.
// Never touches canonical_role ('rider'), backend schema, API, or product terminology.
export function resolveWorkforceLabel(vehicleMix, taxonomy) {
  const types = [...new Set(vehicleMix.map((v) => v.type))];
  if (types.length > 1) return taxonomy.vehicleTypes.mixed_fleet_label;
  const entry = taxonomy.vehicleTypes.vehicle_types.find((v) => v.id === types[0]);
  if (!entry) throw new Error(`unknown vehicle type: ${types[0]}`);
  return entry.natural_language_label;
}

let sequence = 0;
export function buildScenario(input, taxonomy = loadTaxonomy()) {
  sequence += 1;
  const scenario_id = input.scenario_id || `CIL-${String(sequence).padStart(4, '0')}`;
  const vehicle_mix = input.vehicle_mix || proposeVehicleMix({
    orderCount: input.order_profile.count,
    archetypeCategory: input.archetype_category,
    bulky: input.bulky,
    fragile: input.fragile,
  });
  const delivery_team = { ...input.delivery_team, label: resolveWorkforceLabel(vehicle_mix, taxonomy) };

  return {
    scenario_id,
    business_archetype: input.business_archetype,
    order_profile: input.order_profile,
    delivery_team,
    vehicle_mix,
    trigger: input.trigger,
    operational_problem: input.operational_problem,
    personas: input.personas,
    human_behaviour: input.human_behaviour || [],
    environment: input.environment || {},
    emotional_tension: input.emotional_tension || [],
    cefflo_relevance: input.cefflo_relevance || [],
    desired_outcome: input.desired_outcome || [],
    creative_opportunities: input.creative_opportunities || [],
    language_context: input.language_context || { register: 'everyday_business', primary_language: 'ms-MY' },
    risk_flags: [],
    novelty_signature: {
      business_type: input.business_archetype.business_type,
      personas: [...input.personas].sort(),
      vehicle_types: [...new Set(vehicle_mix.map((v) => v.type))].sort(),
      operational_problem: input.operational_problem.primary,
      trigger_type: input.trigger.type,
    },
    validation: { status: 'PENDING', failed_checks: [], scores: {} },
  };
}
