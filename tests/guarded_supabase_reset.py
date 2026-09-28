"""Run Supabase reset only after proving the configured target is local/disposable."""

import os
import subprocess

from environment_guard import TargetRefused, validate_database_target

try:
    target = validate_database_target(
        mutating=True,
        allowed_environments=frozenset({'local'}),
    )
except TargetRefused as error:
    raise SystemExit(f'target_refused: {error}') from error

if target.host not in {'127.0.0.1', 'localhost', '::1'}:
    raise SystemExit('target_refused: reset target is not loopback')

subprocess.run(['supabase', 'db', 'reset', '--local'], check=True, env=os.environ.copy())
