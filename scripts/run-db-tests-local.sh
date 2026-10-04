#!/usr/bin/env bash
# Runs every database/security test module against the DISPOSABLE local
# Supabase only (npx supabase start; port 54322). The environment guard
# refuses any other target, and these flags never point at staging.
set -euo pipefail
cd "$(dirname "$0")/../tests"
export CEFFLO_ENVIRONMENT=local CEFFLO_SUPABASE_PROJECT_REF=local
export CEFFLO_DISPOSABLE_TARGET=1 CEFFLO_ALLOW_MUTATING_TESTS=1
export DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
unset SUPABASE_URL SUPABASE_SECRET_KEY
fail=0
for f in $(grep -l "environment_guard" ./*.py | sed 's#^\./##' | grep -vE '^(environment_guard|guarded_supabase_reset|check_target_identity|validate_backend|test_environment_guard)\.py$'); do
  m=${f%.py}
  # Each module is a script: it asserts on import and exits non-zero on failure.
  if out=$(timeout 400 python3 "$f" 2>&1); then
    echo "PASS $m"
  else
    echo "FAIL $m"; echo "$out" | tail -3 | sed 's/^/     /'; fail=1
  fi
done
exit $fail
