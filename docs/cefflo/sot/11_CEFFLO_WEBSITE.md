**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-12 (Founder baseline closeout — see `docs/cefflo/05_DECISIONS.md` D-30)
**Repo-reconciliation note:** Net-new canonical document, closing a gap flagged in the Phase 01/02 baseline run: CEFFLO Website is one of the five canonical product surfaces (`docs/cefflo/sot/02_ARCHITECTURE.md` §0) but had no dedicated SOT. This document is deliberately lightweight — it establishes product-surface responsibility and phase boundaries only. It does not implement, design, or specify the Website's actual pages/UI.

---

# CEFFLO — WEBSITE (PUBLIC WEB) SOT
**Status:** Canonical Product-Surface SOT
**Version:** 1.0 — 2026-09-12
**Owner:** Founder

## 1. Role
CEFFLO Website is the fifth canonical product surface (`docs/cefflo/sot/02_ARCHITECTURE.md` §0): the public acquisition/commercial surface, Public Web.

It is **not an operational delivery client**. It does not sit in the Vendor → Backend → Driver → Customer operational chain.

## 2. Phase Boundaries

### Phase 03 — Marketing Engine + Content Pilot (current intended scope, NOT implemented by this document)
Deliberately lightweight:
- Cefflo pre-launch landing page;
- clear product positioning and operational-problem framing (what CEFFLO is, per `docs/cefflo/sot/01_PRODUCT_TRUTH.md`);
- Early Access / Waitlist CTA;
- lead capture;
- destination for social/content traffic;
- campaign attribution/analytics hooks where appropriate;
- supports pre-launch audience learning.

Conceptual funnel:
`Social Content → Cefflo Pre-Launch Landing → Early Access / Waitlist → Lead / Audience Signal → Marketing Memory`

This is not the full commercial website.

### Phase 06 — Platform + Commercial (future scope, NOT implemented by this document)
May expand into the full public/commercial web presence:
- complete product pages;
- use-case/solution pages;
- pricing (once `docs/cefflo/sot/10_PRICING.md` is Founder-locked, not before);
- signup/onboarding entry;
- SaaS subscription/commercial entry;
- account/commercial routing where appropriate;
- Razorpay Curlec integration for Cefflo's own SaaS subscription billing where applicable (`docs/cefflo/sot/01_PRODUCT_TRUTH.md` §9 payment boundary).

## 3. Payment Boundary
Curlec is for **Vendor → Cefflo** SaaS subscription/payment only. The Website must never expand this into vendor-customer delivery payments — same boundary as `01_PRODUCT_TRUTH.md` §9 and `07_BUSINESS_LAUNCH_COMMERCIAL.md`.

## 4. Must Not Own
The Website must never independently own or calculate canonical:
- operational orders state;
- coverage;
- zones;
- delivery plans;
- optimization;
- multi-drop runs;
- dispatch;
- driver execution;
- vehicle allocation logic;
- customer delivery state;
- delivery completion truth.

All of the above remain backend-owned per `docs/cefflo/sot/02_ARCHITECTURE.md` §2. The Website may display marketing/product information and handle acquisition/commercial flows only.

## 5. Current Implementation State
`marketing/index.html` is the current built public site (pre-existing, outside the `docs/cefflo/sot/marketing/` knowledge-domain scope, which governs the AI Content Engine, not this surface). No dedicated Phase 03 pre-launch landing page has been built. No Phase 06 commercial website has been built. This document does not authorize building either.

## 6. Relationship to the Marketing Knowledge Pack
This document is the **product-surface** doctrine (what the Website is, its boundaries). `docs/cefflo/sot/marketing/00_MARKETING_KNOWLEDGE_PACK_INDEX.md` and its pack govern the **content/creative** doctrine that will eventually populate this surface. Neither replaces the other.

## 7. Definition of Done
This SOT is functioning correctly when an agent can answer: what is the Website for; what must it never own; what is in scope for Phase 03 vs. Phase 06; where does its traffic come from and where does it send leads — without inventing product/operational capability the Website does not and must not have.
