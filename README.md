# CEFFLO

Canonical CEFFLO source for Vendor, Rider, Customer Tracking and the shared Supabase backend.

- `vendor/` Vendor workspace
- `rider/` Rider operations
- `customer/` token-based customer tracking
- `shared/` public runtime configuration and client
- `supabase/migrations/` reproducible schema, RLS, RPC and Storage
- `tests/` contract and security validation

Apply migrations in timestamp order only to an explicitly identified environment. Never commit database passwords or service-role keys.

Deploy `supabase/functions/tracking-pod` with JWT verification disabled; the function validates the high-entropy tracking token before issuing a five-minute signed POD URL. `SUPABASE_SERVICE_ROLE_KEY` stays in the Supabase function environment only.

## Environment identity

Every build and database command is fail-closed. Set `CEFFLO_ENVIRONMENT` and
`CEFFLO_SUPABASE_PROJECT_REF` explicitly; there is no Production default. The
known Production project `lmaxtrubwdniovxyuqdy` is rejected by every
non-production build and database-test guard.

Builds require the public runtime values too:

```bash
CEFFLO_ENVIRONMENT=local \
CEFFLO_SUPABASE_PROJECT_REF=local \
SUPABASE_URL=http://127.0.0.1:54321 \
SUPABASE_PUBLISHABLE_KEY='<local status output>' \
npm run build
```

The generated `dist/shared/config.js` exposes the selected environment, project
identity, and public Supabase origin. The tracked `shared/config.js` is an
intentional fail-closed placeholder and cannot silently target Production.

## Disposable local Supabase

The Supabase CLI is pinned as a project dependency. Docker must be running.

```bash
npm install
npm run supabase:start
npm run supabase:status
```

Use the local status output to populate an untracked `.env`. Database checks
must use this exact positive identity and loopback database port:

```bash
export CEFFLO_ENVIRONMENT=local
export CEFFLO_SUPABASE_PROJECT_REF=local
export DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
python3 tests/check_target_identity.py
python3 tests/validate_backend.py
```

Mutation and reset require two additional opt-ins:

```bash
export CEFFLO_DISPOSABLE_TARGET=1
export CEFFLO_ALLOW_MUTATING_TESTS=1
python3 tests/e2e_transaction.py
npm run supabase:reset
```

`npm run supabase:reset` is wrapped by the same guard and refuses non-loopback,
ambiguous, hosted, or Production targets. It reapplies only tracked migrations
to the disposable local instance.

## Hosted staging/test readiness

The database identity tools accept `local`, `staging`, and `test`. They never
accept `preview` or `production`. Hosted staging/test execution requires all of:

```bash
export CEFFLO_ENVIRONMENT=staging # or test
export CEFFLO_SUPABASE_PROJECT_REF='<approved-20-character-non-production-ref>'
export SUPABASE_URL='https://<same-ref>.supabase.co'
export DATABASE_URL='postgresql://postgres.<same-ref>:<password>@<region>.pooler.supabase.com:5432/postgres'
```

A direct database URL is also accepted only at the exact host
`db.<same-ref>.supabase.co`. Pooler URLs require a `*.pooler.supabase.com` host
and a database username ending in `.<same-ref>`. Hosted mutation additionally
requires both explicit controls:

```bash
export CEFFLO_DISPOSABLE_TARGET=1
export CEFFLO_ALLOW_MUTATING_TESTS=1
```

These variables authorize nothing by themselves: the hosted target must first
be approved as non-production and disposable. The known Production ref
`lmaxtrubwdniovxyuqdy` is refused when present as the declared ref, API URL,
database hostname, or database username. Missing or mismatched identity also
fails before any connection is attempted.

Static environment validation:

```bash
npm run test:environment
npm run check:environment
```

Legacy PowerShell validation example (the same identity variables are required):

```powershell
$env:DATABASE_URL='postgresql://...'
python tests/validate_backend.py
python tests/e2e_transaction.py
```

Frontend preview (the Supabase publishable key is intentionally public; service-role and database credentials must never be placed in frontend files):

## Billing status

DEFERRED — pending SSM/merchant verification and HitPay production onboarding.

Production beta access is a beta/test entitlement only. It is not a paid subscription and does not create a payment, renewal, invoice, payment method, or billing date.

```powershell
python -m http.server 4173
```

Then open `/vendor/`, `/rider/`, and `/customer/?token=<tracking-token>` from the same origin. Runtime configuration is shared by all three apps through `shared/config.js`.

Production custom-domain mapping uses one Vercel project and the hostname rewrites in `vercel.json`:

- `vendor.cefflo.com` → Vendor
- `rider.cefflo.com` → Rider
- `track.cefflo.com/?token=<tracking-token>` → Customer Tracking

Attach all three domains to the same Vercel project, then configure their DNS records exactly as Vercel reports. Vendor and Rider are installable PWAs. Their service workers cache only the static application shell; navigation is network-first and Supabase/API traffic is never cached.

The retired project `hjrurccjfxtmyftibtgw` is historical evidence only and has no runtime role.
