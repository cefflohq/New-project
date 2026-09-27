#!/usr/bin/env bash
# Read-only G2 inspection. Usage:
#   INSPECT_DATABASE_URL=... ./run-readonly-inspection.sh <label> > <label>.txt
# The URL must come from a read-only credential supplied by the Founder; it is
# read from the environment, never printed, never written to disk by this
# script. Every statement runs inside `begin transaction read only` and the
# session default is also forced read-only, so a write cannot succeed.
set -euo pipefail
label="${1:?label required (e.g. staging, production)}"
url="${INSPECT_DATABASE_URL:?INSPECT_DATABASE_URL is required}"
here="$(cd "$(dirname "$0")" && pwd)"
PGOPTIONS="-c default_transaction_read_only=on" \
  psql "$url" -X -v ON_ERROR_STOP=1 --no-psqlrc -q -f "$here/inspect.sql" \
  | sed "1i # cefflo-inspection label=${label} utc=$(date -u +%FT%TZ)"
