# Production Qualification — 2026-09-27

Scope: canonical `796c2a6` (D-67 → D-70) plus open engineering PRs. Staging
only (`tomvvmwktehexwhktenw`). Production was not accessed.

## Result: RED — not production-ready (external/Founder blockers only)

Staging product qualification passes. Every remaining RED item is an external
release decision or a configuration step that needs Founder action or
production access.

## Evidence (staging)
- **Vendor Mobile (release build):** sign-in → Today/Orders/Zones/Riders/More,
  zero page errors. Analyze clean, 107 tests, live contract 11.
- **Driver (release build):** sign-in → Today/Runs/History/Profile, zero page
  errors. Analyze clean, 26 tests, live contract 11. Full run lifecycle
  (2B.2) and live location (2B.4, PR #8).
- **Vendor Web:**
  - CSV import: invalid row flagged, 2 rows committed as `#CF-009`/`#CF-010`.
  - Dispatch lifecycle verified in 2B.1–2B.3.
- **Customer Tracking:** no order yet → Pickup → On the Way (live location
  with "stops before yours") → Delivered with POD → reload. Issue, cancelled
  and invalid token verified (2B.3).
- **2B.4 measured writes:**

  | Phase | Writes |
  |---|---|
  | LOW | 1 event |
  | MEDIUM | 2 |
  | HIGH | 4/4 |
  | Three viewers | 4 |
  | Hidden | 0 |
  | Stationary | 0 |
  | After delivery | 0 |

- **Security:**
  - Anon reads of 12 operational tables return `[]`.
  - Vendor B sees none of Business A's rows and is refused
    `latest_rider_locations(A)`.
  - Unrelated drivers are refused other riders' keys and location writes.
  - Unauthenticated `create_delivery` returns 401.
  - `#CF-xxx`, `public_ref` or the order UUID used as a token returns null;
    delivered snapshots carry no location.
- **Secrets:** no real credentials in tracked files (placeholders only).
- **Static:** tests OK. Staging static build and the four Flutter builds
  (staging release and prototype, both apps) pass and scan clean.

## RED — blockers
1. **Production database:** migration parity with staging is unknown, and
   applying 202609260001/202609270001/202609270002 needs Founder-authorized
   production access.
2. **Flutter distribution target undefined:** the repo has no Android/iOS
   projects and no hosting route for the Vendor/Driver web builds
   (`rider.cefflo.com` serves the retirement worker).
3. **Hosting and DNS:** Cloudflare cutover is not done, the DNS still points
   at Vercel, `cefflo.com` is parked, and the product subdomains are not
   configured.
4. **Production auth email:** the built-in Supabase email hit its rate limit
   on staging; production needs custom SMTP.
5. **Edge-function configuration:** `tracking-pod` needs
   `CEFFLO_TRACKING_CORS_ORIGINS` set to the deployed customer origin;
   `geocode-order` needs its Mapbox credential.
6. **Monitoring, backup/PITR and rollback:** unverified.

## AMBER — non-blocking
- Cross-product palette alignment debt (D-70).
- Live location is foreground only.
- Multi-business Driver has no selection UI.
- Assignment stays "accepted" after the last stop.
- Reschedule/Other issue reasons are unsupported.
- Vendor Mobile header: the Online toggle is tight against long business
  names.
- Vendor Web "+" FAB is still purple.
- Tracking-token expiry was not re-verified in this session.
