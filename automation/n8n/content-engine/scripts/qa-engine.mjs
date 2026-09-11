// CEFFLO Phase 03 Batch 03E -- Pre-/Post-Production QA.
// Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §15, §16.
// Extends, does not duplicate, scripts/cil-validate.mjs's scenario-level checks
// (Product Truth allowlist, vehicle realism, anti-fabrication, novelty).
import { validateScenario, APPROVED_CEFFLO_CAPABILITIES } from './cil-validate.mjs';

const FORBIDDEN_TERMS = [
  /rider marketplace/i, /driver marketplace/i, /own(s)? (a |the )?rider network/i, /cefflo.{0,20}supplies? (riders|drivers)/i,
  /guaranteed/i, /live gps/i, /automatic route optimi[sz]ation/i, /\d+%\s*(faster|cheaper|savings)/i,
];

const GENERIC_HOOK_PATTERNS = [
  /are you struggling with deliveries/i, /say goodbye to delivery headaches/i, /transform your (business|delivery)/i,
  /work smarter,? not harder/i, /take your business to the next level/i, /revolutioni[sz]e your delivery/i,
];

// §15 Pre-Production QA -- run BEFORE any paid video generation.
export function preProductionQA(scenario, contentPackage, taxonomy, recentHooks = []) {
  const failures = [];
  const scenarioResult = validateScenario(scenario, taxonomy, []);
  if (scenarioResult.status !== 'PASS') failures.push(...scenarioResult.failed_checks.map((c) => `scenario:${c}`));

  const text = JSON.stringify(contentPackage);
  for (const term of FORBIDDEN_TERMS) if (term.test(text)) failures.push(`forbidden_claim:${term}`);
  for (const pattern of GENERIC_HOOK_PATTERNS) if (pattern.test(contentPackage.hook?.hook_bm || '')) failures.push('generic_hook');

  // vehicle terminology correctness (§15: "motorcycle/car/van terminology is correct")
  for (const v of scenario.vehicle_mix) {
    const entry = taxonomy.vehicleTypes.vehicle_types.find((t) => t.id === v.type);
    if (!entry) failures.push(`unknown_vehicle_type:${v.type}`);
  }

  const isDuplicateHook = recentHooks.includes(contentPackage.hook?.hook_bm);
  if (isDuplicateHook) failures.push('insufficiently_distinct_from_recent_output');

  if (!contentPackage.script?.cta_bm) failures.push('missing_cta');

  return { status: failures.length ? 'REJECT' : 'PASS', failed_checks: failures, checked_at: new Date().toISOString() };
}

// §16 Post-Production QA -- run AFTER an asset (video/design/product capture) exists.
export function postProductionQA(asset, scenario) {
  const failures = [];
  if (!asset) return { status: 'REJECT', failed_checks: ['missing_asset'], checked_at: new Date().toISOString() };

  if (asset.lane === 'video') {
    for (const check of ['natural_human_motion', 'believable_workplace_behavior', 'realistic_vehicles', 'object_continuity', 'scene_consistency']) {
      if (asset.qa_flags?.includes(check)) failures.push(`video:${check}`);
    }
    // §11: motorcycle/car/van correctness carries through from the scenario, not invented at QA time.
    const declaredVehicles = new Set(scenario.vehicle_mix.map((v) => v.type));
    for (const shown of asset.vehicles_shown || []) if (!declaredVehicles.has(shown)) failures.push(`vehicle_mismatch:${shown}`);
  }

  if (asset.claims) {
    for (const claim of asset.claims) {
      if (!APPROVED_CEFFLO_CAPABILITIES.includes(claim)) failures.push(`unapproved_claim:${claim}`);
    }
  }

  if (asset.is_ai_generated_ui) failures.push('ai_generated_product_ui_not_allowed'); // §10.4, §13

  const status = failures.length === 0 ? 'PASS' : failures.some((f) => f.startsWith('unapproved_claim') || f === 'ai_generated_product_ui_not_allowed') ? 'REJECT' : 'REVISE';
  return { status, failed_checks: failures, checked_at: new Date().toISOString() };
}
