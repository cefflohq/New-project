// CEFFLO Phase 03 Batch 03I -- Founder Approval state machine.
// Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §17.
// Formalizes the DRAFT -> QA_PASS -> FOUNDER_REVIEW -> APPROVED -> SCHEDULED -> PUBLISHED
// chain (with REVISE / REJECTED / HOLD exits) as one pure, testable function, so both
// n8n workflow Code nodes (07 Founder Approval, 08 Publisher) and this repo's tests
// share one source of truth for legal transitions.

export const STATES = ['DRAFT', 'QA_PASS', 'FOUNDER_REVIEW', 'APPROVED', 'SCHEDULED', 'PUBLISHED', 'REVISE', 'REJECTED', 'HOLD'];

const TRANSITIONS = {
  DRAFT: ['QA_PASS', 'REJECTED'],
  QA_PASS: ['FOUNDER_REVIEW'],
  FOUNDER_REVIEW: ['APPROVED', 'REVISE', 'REJECTED', 'HOLD'],
  APPROVED: ['SCHEDULED'],
  SCHEDULED: ['PUBLISHED'],
  REVISE: ['DRAFT'], // targeted revision re-enters at DRAFT for the affected stage/lane only.
  HOLD: ['FOUNDER_REVIEW'], // Founder can resume review from HOLD.
  PUBLISHED: [],
  REJECTED: [],
};

export function nextState(current, event) {
  if (!STATES.includes(current)) throw new Error(`ERROR_VALIDATION: unknown state ${current}`);
  const allowed = TRANSITIONS[current] || [];
  if (!allowed.includes(event)) {
    throw new Error(`ERROR_VALIDATION: illegal transition ${current} -> ${event}. Publishing must never occur without passing through APPROVED.`);
  }
  return event;
}

// §17: "No content should publish automatically without Founder approval unless
// the Founder explicitly changes the policy later." This guard is the single
// enforcement point the Publisher workflow (08) must call before ever writing
// a publish record -- mirrors the existing ROI 'publisher' stub's own check in
// scripts/generate-workflows.mjs, expressed as a reusable, testable function.
export function canPublish(state, founderDecision) {
  return state === 'APPROVED' || (state === 'SCHEDULED' && founderDecision === 'APPROVE');
}
