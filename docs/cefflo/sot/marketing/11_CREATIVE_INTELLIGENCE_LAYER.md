**Status:** CANONICAL — reconciled and implemented 2026-09-11 (`docs/cefflo/05_DECISIONS.md` D-27). This document operationalizes `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`'s Phase B (Content Intelligence Foundation) in schema/code form. **GATE B (Rider vs Driver terminology) was found, flagged, and is now CLOSED — Founder-resolved 2026-09-11** — see Addendum C1. FG-2 (Content World Baseline, `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`) and this document's own downstream production gates remain separate Founder approvals; building the taxonomy/schema/validator/tests below does not itself activate anything.
**Repo-reconciliation note:** Reconciled against `docs/cefflo/sot/01_PRODUCT_TRUTH.md`, `docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md` §11a, `docs/cefflo/tasks/CEFFLO_GROW_V1_VEHICLE_CAPACITY_SCOPE_ADDENDUM.md`, `docs/cefflo/sot/marketing/09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`, `10_BRAND_VOICE_LANGUAGE_SYSTEM.md`, and the real backend schema (`supabase/migrations/202609030003_s4_11_batch_3_vehicle_capacity_compatibility.sql`), per `docs/cefflo/05_DECISIONS.md` D-27. The body below (§0–§43) is the Founder-supplied source text with one in-place correction, marked where it occurs: §2's Delivery Workforce Terminology and the corresponding line in §29's guardrail list. No other text was altered. All reconciliation analysis, the GATE B conflict, and cross-references to the taxonomy/schema/code implementing this document are isolated in the **Repo Reconciliation Addendum** at the end of this file.

---

# CEFFLO — CREATIVE INTELLIGENCE LAYER

**Master Specification & Implementation Directive**

Status: FOUNDER-DIRECTED MASTER SPEC
Date: 11 September 2026
Scope: Marketing AI Content Engine
Execution owner: Claude
Orchestration: n8n
Authority: Must reconcile with current CEFFLO SOT and latest Founder decisions before implementation.

---

## 0. PURPOSE

This document defines the CEFFLO Creative Intelligence Layer (CIL).

The purpose of CIL is NOT to generate content.

Its purpose is to make the CEFFLO AI Content Engine understand:

- who CEFFLO customers are;
- how their businesses operate;
- what happens during a real local same-day delivery day;
- what operational problems occur;
- who is involved;
- what vehicles are available;
- what human tension exists;
- how CEFFLO relates to that situation;
- which situations are worth turning into content;
- how to prevent repetitive, generic or obviously AI-generated creative.

CIL sits between CEFFLO's source-of-truth intelligence and content generation.

Core doctrine:

«Understand the operational world first. Create content second.»

CEFFLO must not become an AI system that simply generates large volumes of marketing content.

It must become a system capable of understanding the real operational life of businesses running local same-day delivery and turning those realities into believable creative.

---

## 1. FOUNDATIONAL CEFFLO WORLD MODEL

CEFFLO is a:

«Local Same-Day Delivery Operating System for businesses that manage deliveries within their own service area.»

CEFFLO is NOT:

- a rider marketplace;
- a delivery marketplace;
- a logistics company supplying its own rider network;
- a motorcycle-only system;
- a food-only system;
- a home-business-only system.

The vendor owns:

- customer relationship;
- orders;
- delivery operation;
- delivery team;
- drivers;
- vehicles;
- service area.

CEFFLO helps operate that delivery system.

Canonical operational flow:

Orders
→ Coverage
→ Zones
→ Delivery Plan
→ Multi-Drop Runs
→ Drivers
→ Vehicles
→ Dispatch
→ Delivery Execution
→ Customer Updates
→ Delivered Today

Creative Intelligence MUST preserve this operating model.

---

## 2. DELIVERY WORKFORCE TERMINOLOGY

> **GATE B — RESOLVED 2026-09-11 (Founder decision, `docs/cefflo/05_DECISIONS.md` D-27 update).** The section below, as originally supplied, instructed content to use "Driver"/"Delivery Driver" for car and van and reserve "Rider" for motorcycle. That is now **partially** applied, per the Founder's explicit resolution: **the product/backend/API/schema role stays exactly "Rider" everywhere — no Rider → Driver product or schema migration of any kind.** "Driver" is adopted only as a **vehicle-contextual, Creative-Intelligence/Content-World/marketing-copy DISPLAY term**: Motorcycle → **Rider**; Car → **Driver**; Van → **Driver** (alt. "Van Driver"); a mixed/general workforce (more than one vehicle type in a scenario) → **"Delivery Team"**, not a singular Rider/Driver label. This is implemented in `automation/n8n/content-engine/fixtures/cil/vehicle_types.json` (`canonical_role` unchanged at `"rider"`; `natural_language_label` vehicle-contextual) and `scripts/cil-scenario-engine.mjs`'s `resolveWorkforceLabel()`, enforced by a validator check and regression tests (see Addendum C1). This distinction — display term vs. product/schema identifier — must never be collapsed by any future edit.

Previous creative thinking may over-index on the word:

Rider

This must be corrected.

CEFFLO supports a delivery workforce using multiple vehicle types.

Canonical general terms:

- Delivery Team
- Driver
- Delivery Driver

Vehicle-specific terminology:

Motorcycle

The person may naturally be called:

- Rider
- Motorcycle Rider
- Driver

Car

Use:

- Driver
- Delivery Driver

Never call a car driver a rider.

Van

Use:

- Driver
- Van Driver
- Delivery Driver

Never call a van driver a rider.

---

## 3. VEHICLE MODEL

Creative Intelligence must understand at minimum:

MOTORCYCLE

Typical characteristics:

- small payload;
- agile;
- easier parking;
- useful for smaller drops;
- useful for dense urban areas;
- limited bulky-item capacity;
- weather exposure.

CAR

Typical characteristics:

- medium payload;
- protected cargo;
- suitable for fragile or larger products;
- suitable for multiple moderate-size drops;
- more parking constraints than motorcycle.

VAN

Typical characteristics:

- high payload;
- suitable for bulk orders;
- catering;
- larger delivery batches;
- bulky items;
- business-to-business delivery;
- larger multi-drop runs.

These are contextual guidelines, NOT rigid optimization rules.

CIL must not invent product capabilities or vehicle-allocation logic that CEFFLO does not actually support.

---

## 4. VEHICLE REALISM RULE

Vehicle selection inside creative scenarios must make operational sense.

Do NOT randomly assign:

Motorcycle / Car / Van.

Consider:

- item size;
- quantity;
- fragility;
- temperature requirements where relevant;
- number of drops;
- order volume;
- distance;
- urban conditions;
- parking;
- weather;
- business type.

Example:

73 small parcels may plausibly use:

- 3 motorcycles;

or

- 2 motorcycles + 1 car.

A large catering operation may plausibly use:

- cars;
- vans;
- motorcycle support for smaller urgent drops.

A florist transporting large arrangements may plausibly prefer:

- car;
- van.

Creative realism is more important than visual variety.

---

## 5. THE CEFFLO CONTENT WORLD

CEFFLO content must represent a broad operational world.

The system must NOT repeatedly depict:

«food business + motorcycle rider + route problem.»

The content world includes, but is not limited to:

FOOD & MEAL OPERATIONS

- meal prep
- bakery
- catering
- cloud kitchen
- restaurant delivery operation
- frozen food
- home food business
- lunch delivery
- corporate meals

RETAIL & ONLINE COMMERCE

- online sellers
- local ecommerce
- boutique
- gifts
- hampers
- beauty
- skincare
- cosmetics
- local retailers

SPECIAL HANDLING

- florist
- cakes
- fragile goods
- event supplies
- chilled products where appropriate

BUSINESS / INDUSTRIAL

- factories
- distributors
- suppliers
- local wholesalers
- spare parts
- office supplies
- B2B local distribution

Do NOT claim CEFFLO-specific capabilities merely because a business archetype appears here.

The archetype describes the operational world.

Product Truth determines what CEFFLO can actually do.

---

## 6. CREATIVE INTELLIGENCE MODEL

Every scenario should be capable of being represented using the following dimensions:

Business Archetype
× Operational Situation
× Order Profile
× Delivery Requirement
× Delivery Team
× Vehicle Mix
× Operational Constraint
× Persona
× Pain / Tension
× Human Behaviour
× Environment
× CEFFLO Capability
× Operational Outcome
× Creative Format
× Platform Context

Not every scenario needs every field populated.

However, CIL should reason across these dimensions before content generation.

---

## 7. BUSINESS ARCHETYPE

Example fields:

business_type:
business_size:
daily_order_volume:
delivery_frequency:
delivery_window:
service_area_type:
typical_products:
typical_vehicle_mix:
delivery_team_size:
operational_maturity:

Example:

business_type: meal_prep
business_size: small_team
daily_order_volume: 73
delivery_frequency: daily
delivery_window: lunch
service_area_type: urban_multi_zone
delivery_team_size: 3
typical_vehicle_mix:
  - motorcycle
  - car
operational_maturity: manual_to_semi_structured

---

## 8. OPERATIONAL SITUATION LIBRARY

CIL must maintain a growing library of plausible situations.

Initial categories should include:

ORDER PRESSURE

- sudden order spike;
- last-minute orders;
- missing order;
- duplicate information;
- incomplete address;
- delivery instructions changed;
- order added after planning.

DELIVERY TEAM PRESSURE

- driver unavailable;
- driver late;
- insufficient drivers;
- uneven workload;
- driver finishes early;
- one driver overloaded;
- new driver unfamiliar with area.

VEHICLE PRESSURE

- van unavailable;
- motorcycle unsuitable for load;
- car already full;
- bulky order;
- fragile order;
- mixed vehicle fleet.

PLANNING PRESSURE

- too many drops;
- unclear grouping;
- manual route planning;
- wrong delivery grouping;
- delivery window conflict;
- difficult service-area split.

EXECUTION PRESSURE

- traffic;
- rain;
- parking;
- gated property;
- condominium access;
- loading bay delay;
- customer unavailable;
- wrong address;
- driver cannot find entrance.

CUSTOMER COMMUNICATION

- "Order dah keluar ke?"
- "Driver dekat mana?"
- customer asks ETA;
- customer changes instructions;
- recipient unavailable;
- staff repeatedly answering delivery questions.

OWNER / ADMIN PRESSURE

- WhatsApp overload;
- spreadsheet chaos;
- manually calling drivers;
- checking multiple chats;
- trying to remember which orders have left;
- manually dividing orders;
- unclear delivery status.

---

## 9. MALAYSIAN OPERATIONAL REALITY LAYER

CEFFLO creative should feel locally believable.

Situational context may naturally include:

- shoplots;
- condos;
- apartments;
- landed residential areas;
- office towers;
- factories;
- industrial areas;
- guardhouses;
- loading bays;
- parking problems;
- lunch-hour traffic;
- rain;
- peak-hour traffic;
- WhatsApp;
- phone calls;
- mixed BM / English workplace language where natural.

Do not force Malaysian stereotypes.

Do not insert local slang merely to prove that content is Malaysian.

Local reality should come from:

behaviour + environment + language + operational detail.

---

## 10. HUMAN REALITY LAYER

Content should depict humans behaving like real people.

Possible moments:

- owner looking at a long order list;
- admin comparing WhatsApp messages;
- staff counting packages;
- driver loading a vehicle;
- someone asking whether an order has left;
- driver calling about an entrance;
- owner rearranging delivery assignments;
- staff checking delivery status;
- customer sending another WhatsApp message;
- driver returning after a run.

Human behaviour should drive the scene.

Technology should not dominate every opening shot.

---

## 11. LANGUAGE & BRAND VOICE

CEFFLO must sound natural to Malaysian businesses.

Avoid:

- corporate translation;
- literal English-to-BM structure;
- overly polished marketing language;
- unnatural startup jargon;
- unnecessarily formal BM;
- forced slang;
- excessive "aku / kau";
- AI-sounding motivational language.

Preferred characteristics:

- conversational;
- concise;
- observant;
- practical;
- respectful;
- Malaysian;
- operationally aware.

Example of acceptable natural dialogue:

«"Ada 50 order tapi rider ada tiga je. Hmmm, macam mana nak bahagi delivery hari ni?"»

For broader vehicle context:

«"Hari ni 80 delivery. Dua motor, satu kereta, satu van. Nak bahagi macam mana ni?"»

Language can become more colloquial when the situation naturally calls for it while remaining respectful.

---

## 12. CORE STORY PRINCIPLE

CEFFLO is NOT automatically the hero of every story.

Preferred narrative structure:

Business
→ Situation
→ Operational Pressure
→ Human Reaction
→ Need for Structure
→ CEFFLO Intervention
→ More Controlled Operation

Core doctrine:

«The business is the hero.
The operational problem is the story.
CEFFLO is the operating system that helps bring control.»

Avoid:

«"CEFFLO is amazing. Here are five features."»

Prefer:

«"Ada 63 drop hari ni. Seorang driver tak masuk."»

Then allow the story to develop.

---

## 13. SCENARIO ENGINE

CIL must be capable of constructing a scenario object before content generation.

Example:

scenario_id: CIL-0001

business:
  archetype: meal_prep
  scale: small_team

orders:
  count: 73
  delivery_window: before_12_30
  characteristics:
    - lunch_delivery
    - multi_drop

delivery_team:
  expected_drivers: 4
  available_drivers: 3

vehicles:
  - type: motorcycle
    count: 2
  - type: car
    count: 1

trigger:
  type: driver_unavailable

operational_problem:
  primary: workload_redistribution
  secondary:
    - delivery_deadline_pressure
    - customer_eta_questions

persona:
  primary: owner
  secondary:
    - admin
    - driver

human_behaviour:
  - owner_reviews_orders
  - admin_receives_customer_messages
  - drivers_prepare_deliveries

emotional_tension:
  - urgency
  - uncertainty
  - responsibility

cefflo_context:
  relevant_capabilities:
    - delivery_planning
    - multi_drop_runs
    - driver_assignment
    - delivery_status

desired_outcome:
  - clearer_delivery_plan
  - controlled_dispatch
  - better_operational_visibility

Only Product Truth-approved capabilities may populate "relevant_capabilities".

---

## 14. SCENARIO VALIDATION

Before a scenario reaches Content & Strategy, validate:

PLAUSIBILITY

Could this reasonably happen?

BUSINESS FIT

Does it make sense for this business archetype?

VEHICLE FIT

Does the vehicle mix make sense?

HUMAN FIT

Would humans realistically behave this way?

PRODUCT FIT

Can CEFFLO genuinely help with the depicted problem?

LANGUAGE FIT

Does dialogue sound natural?

CREATIVE VALUE

Is there enough tension, curiosity, usefulness or recognition to make worthwhile content?

NOVELTY

Is it materially different from recent output?

Failed scenarios should not proceed downstream.

---

## 15. ANTI-FABRICATION RULE

Hard rule:

«Never invent drama just to make content. Start from a plausible local-delivery operating situation.»

Do NOT invent:

- fake customer testimonials;
- fake revenue;
- fake business results;
- fake number of customers;
- fake time savings;
- fake delivery success percentages;
- unsupported optimization claims;
- fake screenshots;
- fake customer conversations presented as real;
- capabilities not present in Product Truth.

Fictional dramatization is allowed only when clearly used as a scenario/creative representation and not presented as actual customer proof.

---

## 16. ANTI-GENERIC CREATIVE RULES

Reject scripts built primarily from phrases such as:

- "Are you struggling with deliveries?"
- "Say goodbye to delivery headaches."
- "Transform your business today."
- "Work smarter, not harder."
- "Take your business to the next level."
- "Revolutionize your delivery operations."

These may be grammatically correct but are strategically weak and AI-generic.

Instead, begin with specificity.

Example:

«"Pukul 10.40. Lagi 47 order belum keluar."»

or:

«"Van dah penuh. Tinggal 12 drop lagi."»

Specific operational details create recognition.

---

## 17. ANTI-AI VISUAL DOCTRINE

The desired reaction is NOT:

«"Cantiknya AI video ni."»

The desired reaction is:

«"Eh, memang macam operation kedai aku."»

Creative Production should prioritize:

- believable environments;
- natural camera behaviour;
- imperfect human moments;
- realistic workplaces;
- believable Malaysian context;
- normal clothing;
- normal packaging;
- realistic vehicles;
- sensible object placement;
- restrained motion;
- practical lighting.

Avoid excessive:

- cinematic slow motion;
- perfect model-like humans;
- futuristic UI;
- neon environments;
- dramatic camera sweeps;
- impossible warehouse environments;
- pristine generic offices;
- AI-style floating interface overlays;
- unnecessary visual spectacle.

---

## 18. CREATIVE FORMAT MATRIX

A validated operational scenario may become multiple creative executions.

Possible formats:

SITUATIONAL

Short operational scene.

POV

Examples:

- owner POV;
- admin POV;
- driver POV.

DIALOGUE

Natural conversation between:

- owner + staff;
- admin + driver;
- owner + driver.

UGC-STYLE

Creator explains a relatable situation.

PRODUCT-IN-CONTEXT

Situation begins first.

CEFFLO appears naturally as the operational solution.

PRODUCT DEMO

Real product interface demonstrates the relevant workflow.

SCREEN RECORDING

Actual CEFFLO product interaction.

B-ROLL NARRATIVE

Realistic operational footage + narration.

EDUCATIONAL

Explain an operational concept through a real situation.

LIGHT HUMOUR

Recognizable operational frustration without turning the brand into slapstick.

STATIC / CAROUSEL

Situation/problem/solution adapted to visual posts.

One scenario SHOULD be reusable across several formats where appropriate.

---

## 19. CONTENT MULTIPLICATION MODEL

Do not interpret:

140 content/week

as:

140 unrelated ideas/week.

Instead:

Operational Worlds
→ Scenarios
→ Angles
→ Formats
→ Platform Adaptations

Example:

One scenario:

«80 deliveries + 2 motorcycles + 1 car + 1 van.»

Can generate:

- owner POV;
- staff dialogue;
- educational route-planning content;
- product demonstration;
- UGC explanation;
- carousel;
- Threads observation;
- before/after operational story.

This creates scale without sacrificing coherence.

---

## 20. DIVERSITY ENGINE

CIL must track recent creative history.

Prevent excessive repetition across:

- business archetype;
- persona;
- vehicle;
- problem;
- hook structure;
- location;
- emotional tension;
- content format;
- CEFFLO capability;
- opening visual;
- dialogue pattern.

Bad distribution:

20 consecutive videos:

- food seller;
- motorcycle rider;
- late delivery;
- owner stressed.

Better distribution:

- meal prep + mixed fleet + deadline;
- florist + car + fragile arrangement;
- factory + van + multi-drop B2B;
- bakery + motorcycles + morning rush;
- ecommerce + mixed vehicles + order spike;
- catering + vans + event deadline;
- skincare seller + car + multiple local drops.

---

## 21. PERSONA LIBRARY

Initial personas:

OWNER / FOUNDER

Concerned with:

- overall operation;
- customer experience;
- staff;
- delivery cost;
- whether everything gets delivered.

OPERATIONS / ADMIN

Concerned with:

- order list;
- assignments;
- driver coordination;
- customer messages;
- delivery status.

PACKING STAFF

Concerned with:

- preparing correct orders;
- labeling;
- handoff.

DRIVER

Concerned with:

- assigned run;
- drop sequence;
- address;
- customer contact;
- delivery completion.

CUSTOMER / RECIPIENT

Concerned with:

- whether delivery is coming;
- ETA;
- delivery status;
- receiving the order.

Use personas to create different perspectives on the same operational event.

---

## 22. EMOTIONAL TENSION LIBRARY

CIL should understand operational emotion without exaggerating it.

Examples:

- urgency;
- uncertainty;
- responsibility;
- relief;
- frustration;
- confusion;
- time pressure;
- overload;
- anticipation;
- satisfaction when the operation becomes controlled.

Avoid melodrama.

Most CEFFLO tension should feel like:

«"Aduh, macam mana nak settle ni?"»

not:

«catastrophic business crisis.»

---

## 23. CEFFLO INTERVENTION PRINCIPLE

CEFFLO should enter a story only where relevant.

Potential areas, subject to Product Truth:

- order organization;
- coverage;
- zones;
- delivery planning;
- multi-drop runs;
- driver assignment;
- dispatch;
- operational visibility;
- delivery status;
- customer tracking/communication where implemented and approved.

Never force CEFFLO into a problem it does not solve.

---

## 24. CREATIVE INTELLIGENCE OUTPUT CONTRACT

CIL output should be structured.

Recommended schema:

{
  "scenario_id": "",
  "business_archetype": {},
  "order_profile": {},
  "delivery_team": {},
  "vehicle_mix": [],
  "trigger": {},
  "operational_problem": {},
  "personas": [],
  "human_behaviour": [],
  "environment": {},
  "emotional_tension": [],
  "cefflo_relevance": [],
  "desired_outcome": [],
  "creative_opportunities": [],
  "language_context": {},
  "risk_flags": [],
  "novelty_signature": {}
}

Content & Strategy receives this object.

It should NOT need to invent the operational world from scratch.

---

## 25. DOWNSTREAM CONTENT CONTRACT

Content & Strategy transforms validated Creative Intelligence into:

- angle;
- hook;
- script;
- caption;
- CTA;
- format recommendation;
- platform adaptation;
- production instructions.

Separation of responsibilities:

CIL

«What is happening and why does it matter?»

CONTENT & STRATEGY

«What is the best story/angle?»

PRODUCTION ROUTER

«How should we produce it?»

PRODUCTION AGENT

«Create the asset.»

QA

«Is it true, believable, brand-safe and good enough?»

---

## 26. ENGINE ARCHITECTURE

Target conceptual hierarchy:

FOUNDER
   ↓
n8n ORCHESTRATOR
   ↓
INTELLIGENCE SOURCES
   ├── Product Truth
   ├── Brand Brain
   ├── Marketing Memory
   ├── Audience & Market Truth
   └── Content Philosophy
   ↓
CREATIVE INTELLIGENCE LAYER
   ├── Business World Model
   ├── Operational Situation Library
   ├── Delivery Team Model
   ├── Vehicle Context
   ├── Malaysian Reality Layer
   ├── Human Behaviour Layer
   ├── Scenario Engine
   ├── Diversity Engine
   └── Scenario Validator
   ↓
CONTENT & STRATEGY
   ↓
CREATIVE PRODUCTION ROUTER
   ├── Video Lane
   ├── Design Lane
   └── Product Lane
   ↓
PRODUCT TRUTH + BRAND + QUALITY QA
   ↓
FOUNDER APPROVAL / APPROVAL POLICY
   ↓
PUBLISHER
   ↓
ANALYTICS
   ↓
MARKETING MEMORY
   ↺
CREATIVE INTELLIGENCE

---

## 27. FEEDBACK LOOP

Marketing Memory must eventually feed CIL.

Track where possible:

- business archetype;
- scenario;
- hook;
- persona;
- vehicle mix;
- problem;
- format;
- platform;
- creative treatment;
- performance;
- completion rate;
- engagement;
- saves;
- shares;
- comments;
- CTR where applicable;
- conversion signal where available.

CIL should eventually learn patterns such as:

«Operational scenario X resonates strongly with audience Y on platform Z.»

However:

performance must influence exploration, not destroy diversity.

Do not endlessly clone winners.

---

## 28. SCORING MODEL

Candidate scenarios should receive internal scores.

Suggested dimensions:

Operational Plausibility
Audience Recognition
CEFFLO Relevance
Human Relatability
Creative Potential
Visual Potential
Platform Suitability
Novelty
Brand Fit
Production Feasibility

Scores may initially be heuristic.

Do not over-engineer ML before sufficient data exists.

---

## 29. HARD GUARDRAILS

CIL must NEVER:

1. turn CEFFLO into a rider marketplace;
2. imply CEFFLO supplies delivery drivers;
3. assume every driver rides a motorcycle;
4. call car/van drivers riders **in Creative Intelligence / Content World / marketing-copy display text** — resolved 2026-09-11: use "Driver" (car/van) / "Delivery Team" (mixed fleet) as the display term, while the product/backend/API/schema role remains "Rider" everywhere, unchanged. See §2 and Addendum C1.
5. make food businesses the only customer;
6. invent CEFFLO features;
7. fabricate customer proof;
8. create fake performance statistics;
9. generate impossible operational scenarios;
10. use generic AI marketing language as the default;
11. overuse the same business/problem/vehicle combination;
12. sacrifice realism merely for dramatic visuals;
13. let AI visuals redefine Product Truth;
14. publish autonomously unless existing SOT explicitly allows it.

---

## 30. INITIAL TAXONOMY DATA

Implementation should establish expandable canonical taxonomies for:

business_archetypes
personas
vehicle_types
order_profiles
operational_situations
operational_constraints
human_behaviours
environments
emotional_tensions
cefflo_capabilities
creative_formats
platforms
language_contexts
risk_flags

Taxonomies must be:

- machine-readable;
- human-editable;
- versionable;
- extensible;
- auditable.

Avoid hardcoding the entire creative universe directly into n8n nodes.

---

## 31. N8N IMPLEMENTATION PRINCIPLE

n8n remains the central orchestrator.

CIL should be designed as modular stages rather than one giant AI prompt.

Recommended conceptual workflow:

Trigger
↓
Load Product Truth
↓
Load Brand Brain
↓
Load Marketing Memory
↓
Load Creative Intelligence Taxonomy
↓
Select / Construct Operational World
↓
Generate Scenario Candidates
↓
Validate Product Truth
↓
Validate Operational Plausibility
↓
Check Diversity / Recent History
↓
Score Candidates
↓
Select Candidate
↓
Produce CIL Structured Object
↓
Send to Content & Strategy

Exact implementation must respect current repo architecture and existing workflow SOT.

---

## 32. DO NOT BUILD A MONOLITHIC PROMPT

Avoid:

One 10,000-word prompt
→ generate everything
→ script
→ video
→ caption

Prefer:

structured context + specialized stages + explicit validation.

Reasons:

- easier debugging;
- cheaper retries;
- clearer observability;
- easier model replacement;
- better QA;
- easier taxonomy changes;
- easier Founder control.

---

## 33. MODEL ROUTING

CIL should not assume every stage requires the most expensive model.

Implementation should preserve the ability to route:

- deterministic tasks;
- classification;
- taxonomy lookup;
- scenario generation;
- creative reasoning;
- scriptwriting;
- QA

to different models/providers where appropriate.

Do not hard-lock CIL architecture to a single LLM provider unless current SOT explicitly requires it.

---

## 34. OBSERVABILITY

Every CIL execution should eventually expose:

Run ID
Scenario ID
Input sources
Taxonomy version
Model/provider
Scenario candidates
Validation failures
Selected scenario
Scores
Risk flags
Downstream content IDs

Founder should be able to understand:

«Why did the engine create this content?»

---

## 35. FAILURE HANDLING

If Product Truth cannot validate a scenario:

REJECT / HOLD.

If vehicle realism is uncertain:

REVISE.

If dialogue sounds unnatural:

REWRITE.

If scenario duplicates recent output:

ROTATE.

If CIL cannot establish CEFFLO relevance:

DO NOT FORCE CEFFLO INTO IT.

If source truth conflicts:

STOP AND ESCALATE.

---

## 36. CREATIVE QUALITY TEST

Before downstream production, ask:

TEST A — Recognition

Would a local-delivery business owner recognize this situation?

TEST B — Specificity

Could this content belong to any generic SaaS company?

If yes, improve it.

TEST C — Human Reality

Do the people behave naturally?

TEST D — Vehicle Reality

Does motorcycle/car/van usage make sense?

TEST E — Product Truth

Can CEFFLO actually do what is implied?

TEST F — Language

Would a Malaysian business person naturally say this?

TEST G — AI Smell

Does this feel generated primarily because AI can generate it?

If yes, reject or revise.

---

## 37. GOLD STANDARD EXAMPLE

Weak:

«"Managing multiple deliveries can be stressful. CEFFLO helps businesses optimize routes and streamline operations."»

Reject.

Better:

«"Ada 50 order tapi rider ada tiga je. Hmmm, macam mana nak bahagi delivery hari ni?"»

Strong mixed-fleet example:

«"Hari ni ada 80 delivery. Dua motor, satu kereta, satu van. Yang mana nak jalan dulu?"»

Another:

«"Pukul 11. Lagi 36 lunch order belum keluar. Seorang driver pula tak masuk."»

Another:

«"Van dah penuh. Tapi ada 12 drop lagi dekat area sebelah."»

These create an operational world before selling software.

---

## 38. IMPLEMENTATION PHASES

Claude should execute this work coherently end-to-end.

PHASE 1 — REPO/SOT RECONCILIATION

Inspect at minimum the current relevant:

- marketing index;
- Product Truth;
- Brand Brain;
- Marketing Memory;
- Creative Playbook;
- AI Content Engine Orchestrator;
- Founder decisions;
- n8n implementation;
- existing schemas/workflows.

Determine current authority hierarchy.

Do NOT overwrite newer Founder decisions.

---

PHASE 2 — CIL SOT INTEGRATION

Determine correct canonical location for Creative Intelligence Layer.

Integrate without duplicating existing authority.

Update indexes/hierarchy references where necessary.

---

PHASE 3 — TAXONOMY

Create initial machine-readable taxonomy.

Include:

- business archetypes;
- personas;
- vehicles;
- operational situations;
- constraints;
- environments;
- human behaviours;
- emotional tensions;
- creative formats.

Ensure taxonomy is extensible.

---

PHASE 4 — SCENARIO CONTRACT

Implement canonical CIL structured schema.

Include validation.

Document input/output contract.

---

PHASE 5 — SCENARIO ENGINE

Implement scenario candidate construction.

Must support:

- varied businesses;
- motorcycle;
- car;
- van;
- mixed fleets;
- multiple personas;
- operational constraints;
- Product Truth linkage.

---

PHASE 6 — VALIDATION

Implement:

- plausibility checks;
- vehicle realism;
- Product Truth verification;
- brand/language guardrails;
- anti-fabrication;
- diversity checking.

---

PHASE 7 — CONTENT HANDOFF

Connect CIL output to Content & Strategy layer.

Content agent should consume CIL structured context rather than independently inventing the entire business situation.

---

PHASE 8 — MARKETING MEMORY

Prepare data contract for:

CIL → Content → Production → Performance → Marketing Memory.

Do not implement unsupported analytics integrations merely to complete the architecture.

---

PHASE 9 — N8N INTEGRATION

Integrate CIL into the current orchestrator architecture according to existing SOT.

Preserve existing inactive/production safety policies.

Do NOT activate publishing or production schedules without Founder authority.

---

PHASE 10 — TESTING

Create representative test scenarios including at minimum:

1. meal prep + motorcycles;
2. catering + van;
3. florist + car;
4. ecommerce + mixed fleet;
5. factory/B2B + van;
6. bakery + motorcycle/car;
7. driver shortage;
8. order spike;
9. customer communication pressure;
10. mixed-vehicle workload scenario.

Test for:

- schema validity;
- plausibility;
- Product Truth;
- vehicle realism;
- diversity;
- natural language;
- CEFFLO relevance;
- anti-fabrication.

---

## 39. ACCEPTANCE CRITERIA

CIL is acceptable only when:

AC-01

The engine no longer treats rider as the universal delivery-worker concept.

AC-02

Motorcycle, car and van are first-class vehicle contexts.

AC-03

Business archetypes extend substantially beyond food.

AC-04

Operational situations are represented structurally.

AC-05

Content generation receives a structured operational scenario.

AC-06

CEFFLO capability references are Product Truth-grounded.

AC-07

Vehicle context is plausibility-checked.

AC-08

Malaysian operational reality is represented without stereotype forcing.

AC-09

Natural Malaysian language rules are documented.

AC-10

Generic AI hooks are actively discouraged/rejected.

AC-11

Recent-content diversity can be evaluated.

AC-12

Marketing Memory feedback has a defined contract.

AC-13

CIL is observable/debuggable.

AC-14

Existing SOT authority is preserved.

AC-15

No workflow is activated or publishing enabled without Founder authority.

---

## 40. DEFINITION OF DONE

Work is DONE only when:

- current repo/SOT has been audited;
- conflicts have been identified and reconciled;
- Creative Intelligence Layer has a canonical home;
- indexes/hierarchy are updated;
- terminology correction is applied;
- motorcycle/car/van model is represented;
- taxonomy exists;
- scenario schema exists;
- validation rules exist;
- Product Truth guardrail exists;
- diversity mechanism is defined/implemented to the appropriate current-stage depth;
- CIL → Content contract exists;
- Marketing Memory feedback contract exists;
- representative tests pass;
- n8n integration respects current production safety;
- documentation matches implementation;
- evidence/report is produced.

---

## 41. FOUNDER GATES

Claude MUST stop rather than infer if implementation discovers a material conflict involving:

GATE A — PRODUCT TRUTH

This document describes something CEFFLO cannot currently do.

GATE B — SOT AUTHORITY

A newer Founder decision conflicts with this specification.

GATE C — ARCHITECTURE

Current AI Content Engine architecture materially differs from assumptions here.

GATE D — PRODUCTION SAFETY

Implementation would require activating a production workflow, publishing schedule or external action.

GATE E — MATERIAL SCOPE EXPANSION

A proposed implementation requires infrastructure substantially beyond the approved Content Engine.

Non-material implementation details may be resolved by Claude using current repo conventions.

---

## 42. EXECUTION REPORT REQUIRED

At completion Claude must report:

CIL IMPLEMENTATION REPORT

1. Starting repo state
2. SOT files inspected
3. Conflicts discovered
4. Founder decisions preserved
5. Files created
6. Files modified
7. Taxonomy implemented
8. Scenario schema implemented
9. Validation implemented
10. n8n workflow changes
11. Content & Strategy integration
12. Marketing Memory integration
13. Tests executed
14. Test results
15. Remaining limitations
16. Founder gates requiring decision
17. Git diff summary
18. Final status:
    PASS / PASS WITH LIMITATIONS / BLOCKED

Do not claim PASS if material requirements remain unimplemented.

---

## 43. FINAL CREATIVE DOCTRINE

CEFFLO creative intelligence exists to understand this world:

A business wakes up with deliveries that must be completed today.

Orders keep coming.

Someone has to organize them.

Someone has to decide where they go.

There may be:

- two motorcycles;
- three motorcycles;
- a car;
- two cars;
- a van;
- a mixed fleet;
- a small team;
- a larger operation.

Customers want updates.

Drivers need clear work.

Owners need visibility.

Things change during the day.

CEFFLO exists inside that reality.

Therefore:

«Do not start with content.
Start with the operation.»

«Do not start with the feature.
Start with the situation.»

«Do not make AI the creative identity.
Make operational truth the creative identity.»

And above all:

«The business is the hero.
The operational problem is the story.
CEFFLO brings the operation under control.»

---

END OF MASTER SPEC

---

# REPO RECONCILIATION ADDENDUM (added 2026-09-11, per `docs/cefflo/05_DECISIONS.md` D-27)

## C1. GATE B — Rider vs Driver Terminology — RESOLVED 2026-09-11

**Original conflict:** §2 (and the corresponding item in §29) of the source text instructs marketing content to use "Driver"/"Delivery Driver" for car and van operators, reserving "Rider" for motorcycle only. This appeared to conflict with an existing, explicit, Founder-locked decision:

- `docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md` §11a: *"A Rider may operate a Motorcycle, Car, or Van. Vehicle is an attribute of the canonical Rider role, not a separate workspace or identity — 'Driver' is not introduced as a competing term."* Marked Founder-locked: *"These are Founder-locked; they cannot be downgraded by an executor."*
- `docs/cefflo/tasks/CEFFLO_GROW_V1_VEHICLE_CAPACITY_SCOPE_ADDENDUM.md` §2: *"do not create separate operational products or workspace roles called Rider and Driver."*
- `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §1's canonical operating spine: "...Multi-drop Runs → **Riders** → Delivered Today."
- The real, live backend schema: `supabase/migrations/202609030003_s4_11_batch_3_vehicle_capacity_compatibility.sql` adds `rider_vehicle_type` (`motorcycle`/`car`/`van`) as a column on the `riders` table — no `drivers` table anywhere.

**Founder resolution (2026-09-11):** the conflict was real only where it touched *product* terminology. The Founder confirmed both requirements can coexist by scoping them to different layers:

- **Product/backend/API/schema layer — unchanged, locked, permanent:** the canonical role stays **"Rider"** everywhere. No Rider → Driver migration of any kind, ever, at this layer.
- **Creative Intelligence / Content World / marketing-copy display layer — vehicle-contextual:** Motorcycle → **Rider**; Car → **Driver**; Van → **Driver** (alt. "Van Driver"); mixed/general workforce (more than one vehicle type in a scenario) → **"Delivery Team"**, never a singular Rider/Driver label for a mixed fleet.

**Implementation:**
- `fixtures/cil/vehicle_types.json` — `canonical_role: "rider"` unchanged for every entry; `natural_language_label` set per the mapping above; `mixed_fleet_label: "Delivery Team"` added; `_terminology_note` updated to record the resolution.
- `fixtures/cil/personas.json` — the `delivery_person` persona's fixed "Rider" label replaced with a note that the display label is resolved per-scenario, not hardcoded.
- `scripts/cil-scenario-engine.mjs` — new `resolveWorkforceLabel(vehicleMix, taxonomy)`, called from `buildScenario()` and written into `scenario.delivery_team.label`.
- `contracts/cil-scenario.schema.json` — `delivery_team.label` added as a documented, contextual-display-only field.
- `scripts/cil-validate.mjs` — new `WORKFORCE_LABEL` check confirming the label always matches the vehicle-mix mapping exactly.
- `tests/cil_test.mjs` — regression coverage: `canonical_role` stays `"rider"` for all three vehicle types; `natural_language_label` matches Motorcycle→Rider/Car→Driver/Van→Driver; `resolveWorkforceLabel()` verified directly for single-motorcycle, single-car, single-van, and two- and three-type mixed fleets; end-to-end verification through `buildScenario()` for the catering (van), florist (car), ecommerce (mixed) and mixed-vehicle-workload (3-type mixed) representative scenarios; and a direct read of the real `supabase/migrations/202609030003_...sql` file confirming `rider_vehicle_type` is untouched and no competing `driver_vehicle_type` enum exists. **All executed, all passed** — see `docs/cefflo/05_DECISIONS.md` D-27's update for the captured evidence.

**GATE B is closed.** No further Founder input is required on this point unless a future document proposes changing it again.

## C2. Relationship to `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`

This document substantially operationalizes `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`'s Phase B (Content Intelligence Foundation) — it supplies the concrete JSON taxonomy, scenario schema, and validator code that document's Phase B only described in prose, and adds a genuinely new layer (§2–§4 Vehicle Model, absent from `09_...` entirely). Content World (CW-01–06) and this document's Business Archetype taxonomy are cross-referenced, not duplicated — see `automation/n8n/content-engine/fixtures/cil/business_archetypes.json`'s `content_world_ref` fields. §4 Operational Pain (OP-01–14) and this document's Operational Situation Library are similarly cross-referenced (`operational_situations.json`'s `op_ref` fields), not merged.

**This work does not itself grant FG-2** (`09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`'s Content World Baseline gate) — that remains a separate, explicit Founder approval. It does substantially satisfy that gate's Phase B input requirement; the Founder may wish to consider that when deciding FG-2.

## C3. What Was Implemented (Phases 3–8, 10)

- **Taxonomy (Phase 3):** `automation/n8n/content-engine/fixtures/cil/{vehicle_types,business_archetypes,personas,operational_situations,emotional_tensions,creative_formats}.json`.
- **Scenario Contract (Phase 4):** `automation/n8n/content-engine/contracts/cil-scenario.schema.json`.
- **Scenario Engine (Phase 5):** `automation/n8n/content-engine/scripts/cil-scenario-engine.mjs` — deterministic candidate construction, including a vehicle-mix realism heuristic (§4).
- **Validation (Phase 6):** `automation/n8n/content-engine/scripts/cil-validate.mjs` — plausibility, business fit, vehicle fit, human fit, Product-Truth fit (allowlist-based), language fit, creative value, anti-fabrication, and novelty/diversity checks.
- **Marketing Memory contract (Phase 8):** `automation/n8n/content-engine/migrations/202609110001_cil_scenarios.sql` — additive `cil_scenarios` table, **not applied to any database** (see D-27 / the Phase 9 note below).
- **Tests (Phase 10):** `automation/n8n/content-engine/tests/cil_test.mjs` — all 10 representative scenarios plus schema/vehicle-realism/Product-Truth/anti-fabrication/diversity/terminology-guardrail/taxonomy-breadth checks. Executed; all passed (see D-27 for the captured evidence).

## C4. Phase 9 — n8n Integration (documented only, nothing activated)

CIL slots in as an enrichment step inside `CEFFLO - 02 - Research & Angle Miner`, upstream of `CEFFLO - 03 - Master Concept Builder`, per §26's architecture. **No live n8n workflow was created, modified, or imported in this pass** — the taxonomy/engine/validator exist as standalone, tested code ready to be wired into that stage's existing Code node the same way the DeepSeek AI Router is planned to be (`docs/cefflo/tasks/CEFFLO_DEEPSEEK_AI_ROUTER_IMPLEMENTATION_MASTER.md`). This satisfies GATE D (Production Safety) — no workflow was activated, no schedule enabled, no publishing touched.

## C5. Cross-References

- `docs/cefflo/sot/marketing/00_MARKETING_KNOWLEDGE_PACK_INDEX.md` — hierarchy item 13, points here.
- `docs/cefflo/sot/00_INDEX.md` §6 — points here.
- `docs/cefflo/sot/marketing/09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` — Phase B relationship (C2).
- `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` — CIL-specific fields cross-referenced (vehicle_mix, delivery_team, personas).
- `docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md` §11a, `docs/cefflo/tasks/CEFFLO_GROW_V1_VEHICLE_CAPACITY_SCOPE_ADDENDUM.md` — source of the GATE B conflict (C1).
- `docs/cefflo/05_DECISIONS.md` D-27 — Founder decision record for this reconciliation and implementation pass.
