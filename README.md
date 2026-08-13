# CEFFLO

Canonical CEFFLO source for Vendor, Rider, Customer Tracking and the shared Supabase backend.

- `vendor/` Vendor workspace
- `rider/` Rider operations
- `customer/` token-based customer tracking
- `shared/` public runtime configuration and client
- `supabase/migrations/` reproducible schema, RLS, RPC and Storage
- `tests/` contract and security validation

Apply migrations in timestamp order using `DATABASE_URL`. Never commit database passwords or service-role keys.

Deploy `supabase/functions/tracking-pod` with JWT verification disabled; the function validates the high-entropy tracking token before issuing a five-minute signed POD URL. `SUPABASE_SERVICE_ROLE_KEY` stays in the Supabase function environment only.

Validation:

```powershell
$env:DATABASE_URL='postgresql://...'
python tests/validate_backend.py
python tests/e2e_transaction.py
```

The retired project `hjrurccjfxtmyftibtgw` is historical evidence only and has no runtime role.
