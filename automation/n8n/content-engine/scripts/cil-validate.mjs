// CEFFLO Creative Intelligence Layer -- Scenario Validator.
// Source doctrine: docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md §14 Scenario Validation,
// §15 Anti-Fabrication, §20 Diversity Engine, §29 Hard Guardrails.

// Product-Truth-grounded capability allowlist. Every id must trace to
// docs/cefflo/sot/01_PRODUCT_TRUTH.md §4/§5. "rider_assignment" (not
// "driver_assignment") per the GATE B resolution in vehicle_types.json.
export const APPROVED_CEFFLO_CAPABILITIES = [
  'order_organization', 'coverage', 'zones', 'delivery_planning', 'multi_drop_runs',
  'rider_assignment', 'dispatch', 'operational_visibility', 'delivery_status',
  'customer_tracking_where_implemented',
];

const FABRICATION_MARKERS = [
  /\btestimonial\b/i, /\brevenue\b/i, /\bfake\b/i, /\bcustomer\s+count\b/i,
  /\btime\s+saved\b/i, /\bpercent(age)?\s+success\b/i, /\bscreenshot\b/i,
];

export function validatePlausibility(scenario) {
  const failures = [];
  const { order_profile, delivery_team } = scenario;
  if (!(order_profile.count > 0)) failures.push('order_profile.count must be positive');
  if (delivery_team.available > delivery_team.expected) failures.push('delivery_team.available cannot exceed expected');
  if (delivery_team.available < 1) failures.push('delivery_team.available must be at least 1');
  return failures;
}

export function validateBusinessFit(scenario, taxonomy) {
  const known = taxonomy.businessArchetypes.categories.flatMap((c) => c.archetypes);
  if (!known.includes(scenario.business_archetype.business_type)) {
    return [`unknown business_type: ${scenario.business_archetype.business_type}`];
  }
  return [];
}

export function validateVehicleFit(scenario) {
  const failures = [];
  const { vehicle_mix, order_profile } = scenario;
  if (!vehicle_mix.length) failures.push('vehicle_mix must not be empty');
  const totalVehicles = vehicle_mix.reduce((sum, v) => sum + v.count, 0);
  // heuristic plausibility bound, not a capacity optimizer: flag a mix that is wildly
  // out of proportion (e.g. one motorcycle claiming 200 same-window drops).
  const motorcycleCount = vehicle_mix.filter((v) => v.type === 'motorcycle').reduce((s, v) => s + v.count, 0);
  if (motorcycleCount > 0 && !vehicle_mix.some((v) => v.type !== 'motorcycle')) {
    const perMotorcycle = order_profile.count / motorcycleCount;
    if (perMotorcycle > 30) failures.push(`implausible motorcycle-only load: ${order_profile.count} orders across ${motorcycleCount} motorcycle(s)`);
  }
  if (totalVehicles < 1) failures.push('at least one vehicle is required');
  return failures;
}

export function validateHumanFit(scenario) {
  return scenario.personas.length ? [] : ['at least one persona is required'];
}

// GATE B resolution check (docs/cefflo/05_DECISIONS.md D-27): the scenario's
// delivery_team.label must match the vehicle-contextual mapping exactly --
// Motorcycle->Rider, Car/Van->Driver, mixed fleet->Delivery Team.
export function validateWorkforceLabel(scenario, taxonomy) {
  const types = [...new Set(scenario.vehicle_mix.map((v) => v.type))];
  const expected = types.length > 1
    ? taxonomy.vehicleTypes.mixed_fleet_label
    : taxonomy.vehicleTypes.vehicle_types.find((v) => v.id === types[0])?.natural_language_label;
  if (scenario.delivery_team.label !== expected) {
    return [`delivery_team.label '${scenario.delivery_team.label}' does not match expected '${expected}' for vehicle_mix [${types.join(',')}]`];
  }
  return [];
}

export function validateProductFit(scenario) {
  const failures = [];
  for (const capability of scenario.cefflo_relevance) {
    if (!APPROVED_CEFFLO_CAPABILITIES.includes(capability)) {
      failures.push(`cefflo_relevance capability not Product-Truth-approved: ${capability}`);
    }
  }
  return failures;
}

export function validateLanguageFit(scenario) {
  const allowed = ['clean_natural', 'everyday_business', 'pasar_beradab'];
  return allowed.includes(scenario.language_context?.register) ? [] : ['language_context.register must be set to an approved register'];
}

export function validateCreativeValue(scenario) {
  const hasTension = scenario.emotional_tension.length > 0;
  const hasOpportunity = scenario.creative_opportunities.length > 0;
  return hasTension || hasOpportunity ? [] : ['scenario lacks tension or creative_opportunities -- insufficient creative value'];
}

export function validateAntiFabrication(scenario) {
  const failures = [];
  const text = JSON.stringify(scenario);
  for (const marker of FABRICATION_MARKERS) {
    if (marker.test(text)) failures.push(`possible fabrication marker matched: ${marker}`);
  }
  return failures;
}

// Diversity Engine (§20): reject/rotate near-duplicate novelty signatures.
export function validateNovelty(scenario, recentSignatures = []) {
  const sig = JSON.stringify(scenario.novelty_signature);
  const isDuplicate = recentSignatures.some((s) => JSON.stringify(s) === sig);
  return isDuplicate ? ['novelty_signature duplicates a recent scenario -- rotate business archetype, persona, vehicle mix, or problem'] : [];
}

export function validateScenario(scenario, taxonomy, recentSignatures = []) {
  const checks = {
    PLAUSIBILITY: validatePlausibility(scenario),
    BUSINESS_FIT: validateBusinessFit(scenario, taxonomy),
    VEHICLE_FIT: validateVehicleFit(scenario),
    HUMAN_FIT: validateHumanFit(scenario),
    WORKFORCE_LABEL: validateWorkforceLabel(scenario, taxonomy),
    PRODUCT_FIT: validateProductFit(scenario),
    LANGUAGE_FIT: validateLanguageFit(scenario),
    CREATIVE_VALUE: validateCreativeValue(scenario),
    ANTI_FABRICATION: validateAntiFabrication(scenario),
    NOVELTY: validateNovelty(scenario, recentSignatures),
  };
  const failed_checks = Object.entries(checks).filter(([, v]) => v.length).map(([k]) => k);
  const hard_reject = ['PRODUCT_FIT', 'ANTI_FABRICATION'].some((k) => checks[k].length);
  const status = failed_checks.length === 0 ? 'PASS' : hard_reject ? 'REJECT' : 'REVISE';
  return {
    status,
    failed_checks,
    detail: Object.fromEntries(Object.entries(checks).filter(([, v]) => v.length)),
    scores: {},
  };
}
