# CEFFLO Notification System — Canonical Contract and Event Matrix

Status: implemented (in-app) on branch `claude/notification-system`; applied to
staging as migration `202609290001_notification_system`.
Authority: `CEFFLO_NOTIFICATION_SYSTEM_MASTER.md` (Founder execution spec),
`docs/cefflo/18_GROW_NOTIFICATION_ARCHITECTURE.md` (boundary doctrine),
`docs/cefflo/sot/01_PRODUCT_TRUTH.md` §8 and the Product Truth register.

## 1. N0 gap map (before this work)

| Primitive | State before | Decision |
|---|---|---|
| `platform_announcements` + `get_active_announcements()` | EXISTS (global, time-windowed, anon-readable, no audience, no read state) | Kept for platform banners. Not reused for targeted notifications: it cannot target and would leak a business-scoped message publicly. |
| `delivery_events` (immutable operational log, 40+ event types) | EXISTS | **Reused** as the only source of operational notifications (trigger after commit). |
| `admin_audit_log` / `log_admin_action` | EXISTS | Reused for broadcast audit (reason stored). |
| Realtime publication | PARTIAL (orders, rider_assignments, delivery_stops) | `notifications` added. |
| Per-user notification store / read state | MISSING | `notifications` table. |
| Preferences | MISSING (Vendor Web kept a device-only list; mobile screens said "not connected") | `notification_preferences` (enabled, sound). |
| Push tokens / push provider (FCM/APNs/Web Push) | MISSING | **DEFERRED — real blocker** (no provider project, credentials or Founder provider approval). No token table is created until a provider exists. |
| Customer channels (WhatsApp/SMS/push) | MISSING, gated by 18_GROW | **DEFERRED** (Founder provider/consent/template gate). |
| Client notification UI | PARTIAL: Vendor Mobile X-01 and Rider D33 screens existed with session/demo state only; Vendor Web bell disabled | Wired to the backend. |

## 2. Data contract

`public.notifications` (one row per recipient per purpose):

| Field | Meaning |
|---|---|
| `recipient_user_id` | auth user; RLS: a user only reads/deletes their own rows |
| `app` | `vendor` or `rider` — which app's centre shows it |
| `business_id` | business context (nullable for platform-wide) |
| `event_key` | stable key, see matrix |
| `category` | `operational` · `announcement` · `account` |
| `priority` | `normal` · `urgent` (derived from the event type, never from the client) |
| `title`, `body` | English server copy (fallback); clients may localise known `event_key`s from `params` |
| `target` | deep-link `{"screen": "order"\|"runs"\|"riders"\|"rider"\|"none", "id": uuid?}` |
| `params` | template variables (`ref`, `business`, `orders`, …) |
| `source_event_id` / `broadcast_id` | provenance |
| `dedupe_key` | idempotency; `unique(recipient_user_id, dedupe_key)` |
| `read_at` | read state (null = unread) |

Writes happen only in SECURITY DEFINER functions. Clients: `select` (own rows,
REST + realtime), `delete` (own rows), `mark_notifications_read(p_ids, p_app)`,
`mark_notification_unread(p_id)`.

`public.notification_preferences` (per user, all apps): `enabled`, `sound`.
Absent row = defaults (`true`, `true`).

## 3. Event matrix

Recipients: *Vendor team* = active Owners/Operators of the business, minus the
actor. *Rider* = the rider's own signed-in account (`riders.auth_user_id`),
never the actor. Push column = "when a provider exists" (currently deferred).

| event_key | Source (`delivery_events`) | Recipient | Priority | Centre | Banner | Push | Sound | Vibration | Deep-link | Dedupe key |
|---|---|---|---|---|---|---|---|---|---|---|
| `order.new_customer` | `delivery.created` with `actor_role='customer'` (public order page) | Vendor team | normal | yes | yes | deferred | yes | no | order | `de:<event id>` |
| `delivery.issue` | `delivery.issue_reported` by a rider | Vendor team | urgent | yes | yes (stays until dismissed) | deferred | yes | short, mobile | order | `de:<event id>` |
| `run.declined` | `assignment.declined` by a rider | Vendor team | urgent | yes | yes (stays until dismissed) | deferred | yes | short, mobile | runs | `de:<event id>` |
| `rider.joined` | `rider.invite_accepted` | Vendor team | normal | yes | yes | deferred | yes | no | rider | `de:<event id>` |
| `run.completed` | `session.status_changed` → `completed` | Vendor team | normal | yes | yes | deferred | no | no | runs | `de:<event id>` |
| `run.assigned` | `run.built` (rider in metadata); `run.rider_replaced` (new rider) | Rider | urgent | yes | yes (stays until dismissed) | deferred | yes | short | runs | `run:<session>:<rider>` (one per run, replays collapse) |
| `run.removed` | `run.rider_replaced` (previous riders) | Rider | urgent | yes | yes | deferred | yes | short | runs | `de:<event id>:<rider>` |
| `rider.approved` | `rider.approved` | Rider | normal | yes | yes | deferred | yes | no | none | `de:<event id>` |
| `rider.deactivated` | `rider.deactivated` | Rider (account) | normal | yes | yes | deferred | no | no | none | `de:<event id>` |
| `platform.announcement` | FOUNDR `admin_broadcast_notification` | audience (below) | normal | yes | yes | deferred | yes | no | none | `broadcast:<id>` |

Evidence: every source above is written by an existing RPC in
`supabase/migrations` and observed in staging data. Not mapped (no evidence
of a product need or too noisy): preparation/packing, zone changes, run
sequencing, pickup/delivery progress per stop, invites created by the
vendor itself. Account/security events beyond rider approval/deactivation
do not exist in `delivery_events` and are not invented.

Failure isolation: the fan-out trigger catches its own errors (warning only),
so a notification problem never rolls back or alters the operational event.

## 4. FOUNDR broadcast

`admin_broadcast_notification(title, body, audience, business_id, reason)` —
`is_platform_admin()` enforced server-side; reason required and written to
`admin_audit_log` (`broadcast_notification`).

Audiences the data model can honour:
- `vendors` — active Owners/Operators of every business (Vendor app);
- `riders` — active riders with a signed-in account (Rider app);
- `all` — both;
- `business` — active Owners/Operators of one business.

No per-user or segment targeting and no scheduling (not supported by the
model; not faked). `admin_broadcast_audience_size` returns the exact count the
send will target. `admin_list_broadcasts` returns history with
recipients and **read count** — the only delivery status that genuinely
exists while there is no push provider.

`platform_announcements` remains the separate, time-windowed platform banner.

## 5. Presentation contract (per surface, same data)

1. **Centre** — persistent history from `notifications`; unread badge from
   backend `read_at is null`; mark read / mark all read / (mobile) unread,
   delete.
2. **Foreground banner** — shown once per notification id when a new row
   arrives over realtime while the app is open and `enabled = true`.
   Normal: auto-dismiss (~6 s). Urgent: stays until dismissed or opened.
   The banner is transient; the row stays in the centre.
3. **Sound** — played with the banner when `sound = true` and the event's
   sound column is yes (see §6).
4. **Reconnect** — on reconnect/resume the client re-reads the list. It never
   replays banners for rows it already knew or rows older than 2 minutes.
5. **Preferences** — `enabled = false` suppresses banners, sound and (future)
   push. The centre still records every row; operational truth is never
   hidden. OS permission (web Notification API, iOS/Android) is displayed
   separately and truthfully.

## 6. Cefflo Signature Notification Sound — integration contract

**v1.0.0 CANDIDATE (2026-10-06) — implemented, awaiting Founder listening
approval:** an original synthesised sound (no samples, no third-party
or branded audio) — two short rising bell notes G5 → C6 with a soft inharmonic
shimmer, 0.95 s, 48 kHz mono, peak −1 dBFS, RMS ≈ −15.4 dBFS, no voice.
Reproducible from `shared/sounds/cefflo-signature.synth.py`. Delivered:
`shared/sounds/cefflo-signature.wav` (source), `shared/sounds/cefflo-signature.mp3`
(web, 15.7 KB), `apps/vendor_mobile/assets/sounds/cefflo_signature.mp3`
(Flutter in-app, `audioplayers`). Manifest `approved: false`, `version: 1.0.0-candidate` (web keeps the dev tone /
silence until approval; the Vendor App plays the candidate asset).
Still to come with push: Android `res/raw` `.ogg`, iOS `.caf`, and the Driver
app (still on the platform placeholder). The Founder may replace the asset
later at the same paths.

This contract defines where it plugs in.

- **Canonical source asset**: `shared/sounds/cefflo-signature.wav`
  (48 kHz, 16-bit, mono, 0.6–1.2 s, peak ≤ −1 dBFS, integrated ≈ −16 LUFS,
  clean tail, no speech).
- **Delivery formats**:
  - Web: `shared/sounds/cefflo-signature.mp3` (+ `.ogg`), ≤ 60 KB.
  - Android: `android/app/src/main/res/raw/cefflo_signature.ogg`
    (notification channel sound; channel id `cefflo_operational`).
  - iOS: `ios/Runner/cefflo_signature.caf` (≤ 30 s, linear PCM/IMA4) — the
    APNs payload `sound` name.
  - Flutter in-app: `assets/sounds/cefflo_signature.mp3`.
- **Manifest**: `shared/sounds/manifest.json`
  `{ "approved": false, "version": null, "files": {…} }`. Clients play the
  signature only when `approved` is true.
- **Before approval**:
  - production → no custom sound; system/silent only;
  - non-production web → a clearly labelled DEV tone synthesised in the
    browser (`shared/notify-sound.js`), never shipped as an asset;
  - Flutter → `SystemSound.alert` placeholder, flagged in code.
- **Replacing the dev asset**: add the approved files at the paths above,
  set `approved: true` + `version` in the manifest, and bump the service
  worker caches. No code change is needed on web; mobile needs the same
  files in `pubspec.yaml` assets and the platform folders.
- **Permission/fallback**: browsers block audio until the user has interacted
  with the page. Cefflo never retries or loops a sound. OS notification
  channel settings override the app on Android; iOS focus modes are
  respected.

## 7. Surface status (branch `claude/notification-system`)

| Surface | Centre | Banner | Sound | Read/unread | Preferences | Deep-link | Closed-app push |
|---|---|---|---|---|---|---|---|
| FOUNDR | — | — | — | read counts per broadcast | — | — | — |
| FOUNDR Broadcasts | Controls › Broadcasts: compose, preview, exact audience size, reason, confirm, history (recipients, read), audit group | | | | | | |
| Vendor Web | bell + badge + panel | yes (normal 6 s, urgent sticky) | web player (§6) | yes + mark all | Notifications, Sound, browser permission state | order / runs / rider (switches business) | deferred; browser Notification API only while the tab is open but hidden and permission is granted |
| Vendor Mobile | X-01 | overlay banner | Cefflo signature v1 (§6), Sound toggle, one play per 1.5 s burst | yes + mark all, delete (Undo window), clear | V-47: Notifications, Sound | order / zones (runs) / rider | deferred |
| Rider Mobile | D33 + unread dot on every bell | overlay banner, urgent = red edge, sticky, vibration | platform alert placeholder (§6) | yes (long-press) + mark all | Notification settings sheet | run | deferred |
| Customer Tracking | not added (audit: no notification, push, WhatsApp or SMS claims; no polling; uses its own realtime channel) | | | | | | |

Reconnect: every client re-reads the centre when its realtime channel
rejoins and when the app/tab returns to the foreground; banners are never
replayed.

## 8. Deferred (not simulated)

| Item | Why | Needs |
|---|---|---|
| Native push when an app is closed (Vendor/Rider) | No FCM/APNs project, credentials, or provider approval | Founder provider decision + Firebase/APNs setup; then a `push_tokens` table and a send worker |
| Web Push (Vendor Web background) | Same; plus VAPID keys and a send worker | Same |
| Customer notifications (Out for delivery, Approaching, Delivered, Issue) | 18_GROW gate: provider, consent, templates, retention | Founder-authorised package |
| Final signature sound | Audio identity approval | Founder-approved asset per §6 |
| Scheduled broadcasts, per-user/segment targeting | Not in the data model | Founder decision if wanted |
