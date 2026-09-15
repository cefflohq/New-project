// CEFFLO Phase 03 -- small controlled Seedance real-integration pilot.
// Source: Founder Gate directive "SEEDANCE CREDENTIAL GATE", 2026-09-11.
//
// Run manually, once the Founder has supplied a real credential (see
// .env.seedance.local.example -- never paste the key into chat/repo/logs):
//
//   cp .env.seedance.local.example .env.seedance.local   # then fill in the real key
//   node scripts/run-seedance-pilot.mjs
//
// Hard-capped at PILOT_SIZE scenarios (small, controlled -- not bulk
// generation, per the Founder's explicit instruction). Never touches
// publishing; this only exercises submit -> poll -> QA. The credential value
// itself is never printed, logged, or written to the report file below.
import fs from 'node:fs';
import path from 'node:path';
import { loadTaxonomy, buildScenario } from './cil-scenario-engine.mjs';
import { buildContentPackage } from './content-script-engine.mjs';
import { postProductionQA } from './qa-engine.mjs';
import { submitVideoJobLive, pollVideoJobLive, VIDEO_PROVIDER_PRIMARY } from './seedance-adapter.mjs';

const PILOT_SIZE = 3; // small, controlled -- do not raise without a fresh Founder Gate.
const POLL_INTERVAL_MS = 10_000;
const MAX_POLLS = 18; // ~3 minutes, comfortably above the documented 30-120s generation time.
const root = path.resolve(import.meta.dirname, '..');

function loadLocalEnvFile() {
  const file = path.join(root, '.env.seedance.local');
  if (!fs.existsSync(file)) return false;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (key && value && !process.env[key]) process.env[key] = value;
  }
  return true;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function pollUntilTerminal(job, scenario) {
  let current = job;
  for (let i = 0; i < MAX_POLLS; i += 1) {
    current = await pollVideoJobLive(current, scenario);
    if (current.status !== 'PENDING') return { resolved: current, polls: i + 1 };
    await sleep(POLL_INTERVAL_MS);
  }
  return { resolved: { ...current, status: 'TIMED_OUT' }, polls: MAX_POLLS };
}

const PILOT_SCENARIO_INPUTS = [
  {
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
  },
  {
    business_archetype: { business_type: 'grocery', scale: 'small_team', daily_order_volume: 80, delivery_window: 'afternoon' },
    archetype_category: 'retail_and_grocery',
    order_profile: { count: 80, delivery_window: 'afternoon', characteristics: ['multi_drop'] },
    delivery_team: { expected: 4, available: 3 },
    vehicle_mix: [{ type: 'car', count: 2 }],
    trigger: { type: 'sudden_order_spike' },
    operational_problem: { primary: 'order_intake_chaos' },
    personas: ['owner_founder'],
    human_behaviour: ['owner_reviews_orders'],
    emotional_tension: ['time_pressure'],
    cefflo_relevance: ['order_organization', 'zones'],
    desired_outcome: ['clearer_delivery_plan'],
    creative_opportunities: ['pov_owner'],
    language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
  },
  {
    business_archetype: { business_type: 'furniture', scale: 'small_team', daily_order_volume: 15, delivery_window: 'morning' },
    archetype_category: 'business_and_industrial',
    order_profile: { count: 15, delivery_window: 'morning', characteristics: ['bulky'] },
    delivery_team: { expected: 2, available: 2 },
    vehicle_mix: [{ type: 'van', count: 1 }],
    trigger: { type: 'planning_pressure' },
    operational_problem: { primary: 'planning_pressure' },
    personas: ['owner_founder', 'delivery_person'],
    human_behaviour: ['owner_reviews_orders'],
    emotional_tension: ['urgency'],
    cefflo_relevance: ['delivery_planning', 'coverage'],
    desired_outcome: ['clearer_delivery_plan'],
    creative_opportunities: ['pov_owner'],
    language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
  },
].slice(0, PILOT_SIZE);

async function main() {
  loadLocalEnvFile();
  if (!process.env.CEFFLO_SEEDANCE_ARK_API_KEY) {
    console.error(JSON.stringify({ result: 'BLOCKED', reason: 'CEFFLO_SEEDANCE_ARK_API_KEY is not set. Copy .env.seedance.local.example to .env.seedance.local and fill in the real key, or export it in this shell before running.' }, null, 2));
    process.exit(1);
  }

  const taxonomy = loadTaxonomy();
  const results = [];

  for (const input of PILOT_SCENARIO_INPUTS) {
    const scenario = buildScenario(input, taxonomy);
    const contentPackage = buildContentPackage(scenario, taxonomy);
    const entry = { scenario_id: scenario.scenario_id, business_type: input.business_archetype.business_type, vehicle_mix: input.vehicle_mix };
    try {
      const job = await submitVideoJobLive(scenario, contentPackage);
      entry.job_id = job.job_id;
      entry.submit_success = true;
      const { resolved, polls } = await pollUntilTerminal(job, scenario);
      entry.polls = polls;
      entry.final_status = resolved.status;
      if (resolved.status === 'COMPLETED') {
        const qa = postProductionQA(resolved.asset, scenario);
        entry.qa_status = qa.status;
        entry.qa_failed_checks = qa.failed_checks;
        entry.video_url = resolved.asset.video_url;
        entry.accepted = qa.status === 'PASS';
      } else {
        entry.accepted = false;
        entry.failure_reason = resolved.error ?? resolved.ark_status ?? resolved.status;
      }
    } catch (error) {
      entry.submit_success = false;
      entry.accepted = false;
      entry.error = error.message; // Error.message never includes the raw key -- only fetch() response bodies could, and ARK's own API does not echo the Authorization header back.
    }
    results.push(entry);
  }

  const accepted = results.filter((r) => r.accepted).length;
  const summary = {
    result: 'PILOT_COMPLETE',
    provider: VIDEO_PROVIDER_PRIMARY,
    pilot_size: results.length,
    accepted,
    rejected: results.length - accepted,
    submit_failures: results.filter((r) => r.submit_success === false).length,
    cost_note: 'Real per-job cost is not returned by the ARK generation/poll API -- this script deliberately reports null/none rather than fabricate a figure. Real spend must be read from Volcengine\'s own billing/usage console or API, which is not yet integrated.',
  };

  const outFile = path.join(root, `seedance-pilot-report-${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
  fs.writeFileSync(outFile, JSON.stringify({ summary, results }, null, 2));
  console.log(JSON.stringify({ ...summary, report_file: outFile }, null, 2));
}

main();
