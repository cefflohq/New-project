# Push notifications (closed-app alerts) — Web Push first

Founder 2026-10-11: open the push gate for **Android and Web/PWA**. This
document covers Phase P1 (Web Push). Phase P2 (native Android, FCM) needs a
Founder-owned Firebase project and is not built yet. iOS (APNs) stays on hold.

Staging only until a production release is approved.

## What it does

When a row is written to `public.notifications` (the existing notification
centre — no new event sources), each device the recipient has opted in on
gets an OS notification even when Cefflo is closed: Vendor Web, Vendor App
(web/PWA, incl. Operator/Helper hosts) and Driver App (web/PWA). Android
Chrome delivers Web Push to the phone's notification tray.

The in-app notification, read state and the Cefflo Signature Sound are
unchanged. OS push uses the device's own notification sound (browsers do not
allow a custom sound).

## Flow

1. The user turns on **"Alerts when Cefflo is closed"** on a device. The
   browser asks for permission; the page subscribes with the VAPID public key
   (`GET /functions/v1/push/vapid`) through a dedicated service worker
   (`push-sw.js`, its own scope, never the Flutter app worker).
2. The page calls `push_register(app, endpoint, p256dh, auth, base_url)`.
3. `AFTER INSERT` on `notifications` → `net.http_post` (pg_net) to
   `/functions/v1/push/send` with only the notification id and a shared
   secret. Failures are swallowed (notification work never blocks the
   operational write — 18_GROW_NOTIFICATION_ARCHITECTURE doctrine).
4. The function (service role) loads the notification, the recipient's
   preference and their subscriptions for that `app`, and sends an encrypted
   Web Push (RFC 8291 aes128gcm, VAPID RFC 8292). 404/410 removes the
   subscription; other failures increment `failures` (removed at 5).

## Security

| Control | Rule |
|---|---|
| Subscriptions | `push_subscriptions` RLS: a user reads/deletes only their own rows; writes only via `push_register` / `push_unregister` (SECURITY DEFINER, `auth.uid()`). An endpoint re-registered by another user moves to that user (shared device sign-in), so a signed-out user never receives the next user's alerts. |
| Sign-out | Clients call `push_unregister` for the device endpoint before signing out. |
| Send trigger | `/push/send` requires `x-push-secret` (constant-time compare) = `CEFFLO_PUSH_WEBHOOK_SECRET`; the DB reads the same value from Vault (`push_webhook_secret`). Body carries only an id; content is read server-side. |
| Payload | Title, body, a relative link and a tag — the same text the notification centre already shows that user. No tokens, no customer phone numbers beyond what the notification itself contains. |
| Preferences | `notification_preferences.enabled = false` stops push too. |
| Keys | VAPID private key and webhook secret are Supabase function secrets, never in the repo or client. VAPID public key is public by design. |
| Endpoint origins | Only `https://` endpoints are accepted (push services are https). |

## Limits / not claimed

- iPhone: Web Push works only for an installed PWA on iOS 16.4+, and native
  iOS is on hold — do not claim iPhone closed-app alerts.
- Native Android app (APK/Play) closed-app alerts: P2, needs FCM.
- No custom sound on OS notifications.
