// CEFFLO Phase 03 Batch 03D -- Content & Script Engine.
// Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §8 (staged narrowing),
// §7 (language/brand voice), §9 (cost doctrine: deterministic by default, stronger
// reasoning only where it materially helps).
//
// Deterministic template engine by default -- this is the LOW-cost path per §9.
// generateContent() never calls a paid LLM. routeToAIRouter() is the explicit,
// documented seam where a live DeepSeek call (per
// docs/cefflo/tasks/CEFFLO_DEEPSEEK_AI_ROUTER_IMPLEMENTATION_MASTER.md) would
// plug in for HIGH/MAX-tier scenarios once that Master's own Founder gates clear --
// it is not called here, and defaults to the deterministic path when absent.
import { resolveWorkforceLabel } from './cil-scenario-engine.mjs';

const HOOK_FAMILIES = {
  numerical_pain: (s) => `${s.order_profile.count} order tapi ${labelForMix(s)} ada ${teamCount(s)} je. Hmm... macam mana nak bahagi delivery hari ni?`,
  time_pressure: (s) => `Pukul ${randomHourNotation(s)}. Lagi ${Math.max(1, Math.round(s.order_profile.count * 0.4))} order belum keluar.`,
  capacity: (s) => `${vehicleSummary(s)} dah penuh. Tinggal lagi ${Math.max(1, Math.round(s.order_profile.count * 0.15))} order.`,
  manual_work: () => 'Setiap pagi masih copy alamat satu-satu?',
  operational_question: (s) => `Yang area ${s.environment?.area || 'ni'} siapa nak ambil?`,
};

function teamCount(s) { return s.delivery_team.available; }
function labelForMix(s) { return resolveWorkforceLabel(s.vehicle_mix, s._taxonomy).toLowerCase(); }
function vehicleSummary(s) {
  const types = s.vehicle_mix.map((v) => v.type);
  return types.length > 1 ? 'Delivery team' : `${s.vehicle_mix[0].count} ${s.vehicle_mix[0].type}`;
}
function randomHourNotation(s) {
  // Deterministic, not random: derive a plausible hour from order count so output is reproducible.
  return String(10 + (s.order_profile.count % 3));
}

function pickHookFamily(scenario) {
  if (scenario.trigger?.type === 'sudden_order_spike' || scenario.operational_problem?.primary === 'order_intake_chaos') return 'time_pressure';
  if (scenario.trigger?.type?.includes('unavailable') || scenario.operational_problem?.primary === 'workload_redistribution') return 'capacity';
  if (scenario.operational_problem?.primary === 'planning_pressure') return 'operational_question';
  return 'numerical_pain';
}

// Section 7: natural Malaysian register, never a literal English-to-BM translation --
// this engine writes BM and EN independently from the same scenario, per
// docs/cefflo/sot/marketing/10_BRAND_VOICE_LANGUAGE_SYSTEM.md §3.1.
export function generateHook(scenario, taxonomy) {
  scenario._taxonomy = taxonomy;
  const family = pickHookFamily(scenario);
  return { hook_family: family, hook_bm: HOOK_FAMILIES[family](scenario), register: scenario.language_context?.register || 'everyday_business' };
}

export function generateScript(scenario, taxonomy, hook) {
  const workforceLabel = resolveWorkforceLabel(scenario.vehicle_mix, taxonomy);
  const outcome = scenario.desired_outcome?.[0] || 'clearer_delivery_plan';
  return {
    hook_bm: hook.hook_bm,
    problem_beat: `${scenario.business_archetype.business_type.replaceAll('_', ' ')}, ${scenario.order_profile.count} order, ${workforceLabel.toLowerCase()} ${teamCount(scenario)} orang.`,
    product_beat: 'Susun ikut zone. Siapkan delivery plan. Assign ' + workforceLabel.toLowerCase() + '.',
    outcome_beat: outcome.replaceAll('_', ' '),
    cta_bm: 'Lihat macam mana Cefflo bantu susun operation hari ni.',
    structure: 'problem_scene -> real_product_proof -> operational_outcome', // §12/§14 of 11_CREATIVE_INTELLIGENCE_LAYER.md
  };
}

export function generateCaption(scenario, script) {
  return `${script.hook_bm} ${script.outcome_beat}.`.slice(0, 220);
}

const PLATFORM_ADAPTERS = {
  meta: (script, caption) => ({ lane: 'meta', destinations: ['instagram', 'facebook'], format: 'reel', duration_seconds: 20, aspect_ratio: '9:16', hook: script.hook_bm, caption, cta: script.cta_bm }),
  tiktok: (script, caption) => ({ lane: 'tiktok', destinations: ['tiktok'], format: 'short_form_video', duration_seconds: 18, aspect_ratio: '9:16', hook: script.hook_bm, first_2_seconds: script.hook_bm, caption, cta: script.cta_bm }),
  threads: (script) => ({ lane: 'threads', destinations: ['threads'], format: 'text_post', opening_line: script.hook_bm, body: script.problem_beat + ' ' + script.product_beat, cta_or_question: script.cta_bm }),
};

export function adaptForPlatforms(script, caption, lanes = ['meta', 'tiktok', 'threads']) {
  return lanes.map((lane) => PLATFORM_ADAPTERS[lane](script, caption));
}

// Explicit, documented seam for a live AI Router call (HIGH/MAX reasoning tier).
// Not invoked by buildContentPackage() below -- callers opt in explicitly once
// the DeepSeek AI Router Master's own Founder gates are cleared.
export async function routeToAIRouter(_scenario, _workloadTier, _aiRouterClient) {
  throw new Error('AI Router not wired in Phase 03 -- deterministic content-script-engine.mjs is the default path per §9 cost doctrine.');
}

export function buildContentPackage(scenario, taxonomy) {
  const hook = generateHook(scenario, taxonomy);
  const script = generateScript(scenario, taxonomy, hook);
  const caption = generateCaption(scenario, script);
  return {
    scenario_id: scenario.scenario_id,
    hook,
    script,
    caption,
    platform_packages: adaptForPlatforms(script, caption),
    generation_provider: 'deterministic',
    generation_cost: 0,
  };
}
