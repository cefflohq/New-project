# Phase 2B.4 — Rider Live Location (Demand-Aware Adaptive Tracking)

Status: DESIGN — awaiting Founder approval (D-66). No runtime code in this
change. Staging-only when implemented. Production untouched.

## 1. What exists today (inspected on canonical `dfbe070` and staging)

| Piece | State |
|---|---|
| `rider_locations` | Append-only table (`business_id, rider_id, assignment_id, latitude, longitude, accuracy, heading, speed, recorded_at`), index `(rider_id, recorded_at desc)`. Staging: 0 rows. |
| `record_rider_location(...)` | The only write path (F2-08). Verifies the caller is the rider, derives `business_id` server-side, attaches the active assignment. |
| `latest_rider_locations(business_id)` | Vendor read, latest row per rider, tenant-checked. |
| RLS | Vendor may select its own business's rows. Rider may insert own rows. **No anon access.** |
| Realtime | Publication `supabase_realtime` = `orders, rider_assignments, delivery_stops`. `realtime.send` exists on staging. |
| Customer Tracking | Anonymous, token-only `public_tracking(p_token)`, rate-limited 10 req / 60 s per token. Refresh only on open / focus / bfcache return (no timer). No coordinates today. |
| Driver app | Does not sample or write location. Knows its run, stop sequence and lifecycle. |
| Riders → sessions | `sessions_rider` policy already lets a rider read its own delivery sessions. |

Consequence: Realtime **Postgres Changes cannot reach the customer** (anonymous
customers pass no RLS). **Realtime Broadcast and Presence on a channel can.**
Neither needs a new service.

## 2. Architecture in one picture

```
Driver phone                                   Supabase                          Customer page (visible)
────────────                                   ────────                          ───────────────────────
OS location stream (distance-filtered)
   │  local samples, never all sent
   ▼
Upload gate  ── meaningful? ──► record_rider_location()  ── one row ──►  public_tracking(token)
   ▲   (movement, staleness per mode,           (unchanged)                  returns latest coordinate
   │    lifecycle events)                                                    only for THIS order,
   │                                                                          only while trackable
   │  after a successful write: broadcast "loc" (no coordinates) ──► channel trk:<live_topic> ──► nudge → fetch once
   │
   └── reads Presence on trk:<live_topic> ◄───── presence {k} ◄──────── only while page is visible
         → demand level LOW / MEDIUM / HIGH
```

- The rider writes **one** coordinate. Every authorized viewer of that run is
  served by it. Viewers never cause extra writes per viewer.
- The demand signal is **Realtime Presence**, which is ephemeral and cleared
  automatically on disconnect. Nothing is stored in the database, and no
  presence infrastructure is built.
- Customers get coordinates **only through the token-checked
  `public_tracking`**. A broadcast is only a "something changed" nudge. It never
  carries coordinates, so a spoofed broadcast can at most trigger a
  rate-limited fetch.

## 3. Demand levels (computed on the Driver phone, per run)

Each visible viewer announces Presence with an opaque key `k`. The key is
issued by `public_tracking` and maps to its stop. The Driver app maps `k` to
its own stop list and computes

`stops_ahead = number of undelivered stops sequenced before that stop`.

| Level | Condition (max over present viewers) |
|---|---|
| **LOW** | No visible viewer on the run. |
| **MEDIUM** | At least one visible viewer, and every visible viewer's stop has `stops_ahead ≥ 1`. |
| **HIGH** | A visible viewer whose stop is current or next (`stops_ahead = 0`), or whose order is `arrived`. |

Before the sequence is locked (`start_run_delivery`), a viewer counts at most
as MEDIUM.

The five customer behaviours:

1. **Never opens:** no Presence, so LOW. No customer-driven writes or reads at all.
2. **Occasional checker:** each open makes one `public_tracking` fetch. If the latest coordinate is within the current level's staleness limit, it is shown and no write is forced. If stale, the viewer's Presence raises the level and the rider's upload gate fires once.
3. **Short active view (20–60 s):** MEDIUM or HIGH while visible, and only meaningful moves propagate. When the page closes, Presence drops and the level falls back.
4. **Tab left open but hidden:** on `visibilitychange → hidden`, the page stops tracking Presence and leaves the channel, so demand stops. On `visible`, it fetches once, then re-joins.
5. **Actively waiting and next in line:** HIGH, with the tightest thresholds. This stops as soon as the order is `delivered`, `cancelled` or `issue`.

## 4. GPS sampling vs backend writes

- **Sampling (local, cheap):** foreground OS location stream with a
  `distanceFilter` of **20 m** and best-for-navigation accuracy only while a
  run is `picked_up`→`arrived`. There is no sampling outside an active run and
  no background location (not in scope). Fixes with accuracy > **50 m** are
  discarded.
- **Upload gate (the only thing that writes).** A sample is uploaded only if
  **one** of these rules fires:

| Level | Movement rule (moved ≥ X since last upload, and ≥ min gap) | Staleness fallback (only if moved ≥ 25 m noise floor) |
|---|---|---|
| LOW | ≥ **500 m** and ≥ **120 s** | **10 min** |
| MEDIUM | ≥ **150 m** and ≥ **30 s** | **3 min** |
| HIGH | ≥ **50 m** and ≥ **10 s** | **60 s** |

- **Events force one upload** (with the next good fix, respecting a 10 s
  minimum gap):
  - `start_pickup_run` / pickup confirmed;
  - `start_run_delivery`;
  - each `out_for_delivery` / `arrived` transition;
  - `complete_delivery` / issue;
  - the level rising (e.g. LOW→HIGH) while the last upload is older than the new level's staleness limit.
- **Stationary rider** (moved < 25 m): no repeated coordinates at any level.
  The customer sees the true `recorded_at` ("Updated 4 min ago"), which is
  honest.

### Why these numbers

- **25 m noise floor, 20 m sampling filter:** urban phone GPS is typically
  5–20 m accurate and multipath drifts 10–30 m, so anything smaller uploads
  noise.
- **HIGH 50 m / 10 s:** at urban rider speed (15–30 km/h, about 4–8 m/s),
  50 m is about 6–12 s. The customer sees the rider turn into the street,
  which is the useful moment. A tighter setting only makes the map animate
  more and costs writes.
- **MEDIUM 150 m / 30 s:** "my rider is on the way, a few stops away." Moves at
  street-block granularity are enough.
- **LOW 500 m / 120 s:** operational trace for Vendor and a truthful last
  position if someone opens later. It is not customer-facing live data.
- The **10 req / 60 s** tracking rate limit already bounds HIGH customer
  fetches (≥ 10 s gap), consistent with this.

## 5. Customer page behaviour

- **Open or visible:** one `public_tracking` fetch. If the order is trackable
  (`picked_up` / `out_for_delivery` / `arrived`) and the response carries
  `live`, join `trk:<topic>`, track Presence `{k}`, and listen for `loc`.
- **On `loc`:** fetch `public_tracking` once, debounced so fetches are at
  least 10 s apart.
- **Safety fallback while visible:** if no nudge arrives within the level's
  staleness limit (HIGH 60 s / MEDIUM 3 min), fetch once. That is the only
  timer, and it only runs while visible.
- **Hidden:** untrack Presence and unsubscribe. No reads.
- **Delivered, cancelled or issue:** leave the channel. The response no longer
  contains `rider_location` or `live`.
- ETA and distance stay as today: shown only when `compute_order_eta` returns
  a truthful range, otherwise "—". No interpolated movement.

This supersedes the 2B.3 "on demand, never on a timer" refresh rule **only**
while the page is visible and the order is trackable.

## 6. Latest vs history

- Customers need **latest coordinate + `recorded_at` only**. `public_tracking`
  returns just the newest row for the order's rider/assignment, recorded after
  pickup, and only if it is ≤ 15 min old. Nothing older is returned, and no
  breadcrumbs.
- `rider_locations` keeps its append-only rows because Vendor operations and
  audit use them. The demand-aware gate keeps growth to about 255 rows per
  rider-day instead of 1,200.
- **Open Founder decision (not blocking):** a retention window (proposal:
  delete rows older than 30 days). No new latest-location table is needed,
  because the existing `(rider_id, recorded_at desc)` index makes the latest
  lookup a single index probe.

## 7. Backend contract changes (one new migration)

1. `rider_assignments.live_topic uuid not null default gen_random_uuid()` is
   the unguessable channel name per rider-run. It is not an internal identifier
   anyone can derive, it is readable by the assigned rider through existing
   RLS, and it is never listable by anon.
2. `public_tracking(p_token)` is extended **additively**. Only while the order
   is `picked_up`, `out_for_delivery` or `arrived` does it return:
   - `rider_location`: `{lat, lng}` rounded to 4 decimals (≈11 m), plus
     `accuracy_m` and `recorded_at`. It is the latest row for that
     assignment's rider, recorded after the assignment's pickup and ≤ 15 min
     old; otherwise null.
   - `live`: `{topic: 'trk:' || live_topic, key: <per-order opaque key>}`. The
     key is `left(encode(digest(token_hash || live_topic, 'sha256'),'hex'),16)`,
     and the Driver app can compute it from what it can already read.
   - `stops_ahead`: number of undelivered stops before this order in the
     locked sequence (null before lock). This is truthful context ("2 stops
     before yours"), not an ETA.
3. No change to `record_rider_location`, RLS, `latest_rider_locations`, the
   Realtime publication, or any other RPC. The `loc` broadcast is sent by the
   Driver app after its write succeeds, so no database trigger is needed.

**Migration required: YES** (items 1–2). The Driver presence-key lookup needs
the order's `token_hash` hashed with `live_topic`. Rather than exposing
`tracking_tokens` to riders, the migration adds a rider-scoped read,
`rider_live_keys(p_rider_id)`, returning `(order_id, key)` for the rider's own
active orders. It is the smallest safe addition.

## 8. Security

- Coordinates are reachable only with a valid token, for that order, while it
  is trackable, and only the latest point within 15 min.
- An unknown or finished order, `#CF-xxx`, `public_ref` or UUID returns
  nothing, as today.
- The channel topic is unguessable, and a viewer learns only its own run's
  topic. Broadcasts carry no coordinates.
- Spoofed Presence or `loc` messages can at worst raise one run's upload level,
  which is bounded by the HIGH gate at ≤ 1 write / 10 s, or cause rate-limited
  fetches. No data is disclosed.
- Customers on the same run share a topic. Each still receives coordinates
  only via its own token. Presence keys are opaque, and presence never reveals
  another customer's order or address.
- No change to Vendor or Driver RLS. Vendor B isolation is unchanged.

## 9. Load model

**Assumptions** (per rider per day):
- 30 orders, one 5-hour active delivery window, urban 20 km/h when moving.
- The rider is moving 60% of the active window and stationary 40% (handovers,
  traffic, waiting).
- Viewers:
  - 40% of customers never open the link;
  - 35% check occasionally (4 opens × 30 s);
  - 20% watch actively for short spells (2 × 60 s);
  - 5% wait actively (10 min near their stop);
  - some overlap, where several customers watch the same rider.

**A — naive fixed 15 s:**
- The rider writes every 15 s for 5 h, giving **1,200 writes**.
- Each opened page polls every 15 s while open, visible or not. With an
  average of 20 min open, 18 opened orders × 80 polls gives **1,440 reads**.
- 3 customers watching the same rider triple the reads but not the writes.

**B — demand-aware:**
- LOW: about 90 writes (moving 180 min, gated at 500 m / 120 s).
- MEDIUM: about 40 (≈33 visible far-viewer minutes).
- HIGH: about 60 (≈15 waiting minutes at 50 m / 10 s).
- Events: about 65 (2 per order plus run starts).
- Stationary time contributes 0, and never-open customers contribute 0.
- Total ≈ **255 writes**.
- Reads: about 54 opens, plus about 100 nudge-fetches during visible minutes,
  plus about 6 safety fetches, ≈ **160 reads**.
- Realtime: about 60 presence joins plus about 100 broadcasts delivered to
  present viewers only.

| Riders | A writes/day | B writes/day | A reads/day | B reads/day | A avg writes/s* | B avg writes/s* |
|---:|---:|---:|---:|---:|---:|---:|
| 100 | 120 K | 25.5 K | 144 K | 16 K | 6.7 | 1.4 |
| 1,000 | 1.2 M | 255 K | 1.44 M | 160 K | 67 | 14 |
| 10,000 | 12 M | 2.55 M | 14.4 M | 1.6 M | 667 | 142 |
| 100,000 | 120 M | 25.5 M | 144 M | 16 M | 6,667 | 1,417 |

*Averaged over the 5-hour delivery window.

- **Reduction:** writes about **79%** lower, customer reads about **89%**
  lower, and history rows about 79% lower.
- **Different cost drivers:**
  - A grows with riders × time, whether or not anyone is watching.
  - B grows with movement and actual demand.
  - Stationary riders and unopened links cost about nothing.
  - A second or third viewer on the same rider adds only its own fetches,
    never writes.
- These are planning estimates, not a bill.

## 10. Acceptance criteria (for implementation, staging only)

1. The Driver app uploads only through the gate. Unit tests show that
   stationary, noise, LOW, MEDIUM, HIGH and event cases produce the expected
   write/no-write decisions.
2. Presence joins and leaves on open, visible, hidden and close. A hidden tab
   generates zero reads or presence.
3. `public_tracking` returns `rider_location` / `live` only while trackable,
   only for its own order, and only for a point ≤ 15 min old. Once delivered,
   cancelled or issue, it returns null.
4. Three simultaneous viewers of one rider produce the same number of rider
   writes as one viewer.
5. Stop #2 and stop #14 viewers produce HIGH vs MEDIUM behaviour on the Driver
   phone.
6. Negative tests:
   - `#CF-xxx`, `public_ref` and UUID return nothing;
   - another order's token gets only its own order;
   - anon cannot select from `rider_locations`;
   - a spoofed `loc` message causes no disclosure.
7. Staging E2E with measured write and read counts compared with this model.
   No fabricated ETA, distance or movement.
8. Production is untouched. The migration goes to Production only in a
   separate approved release.
