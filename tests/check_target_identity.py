"""Harmless, sanitized connectivity and database identity check."""

import json

import psycopg

from environment_guard import TargetRefused, validate_database_target

try:
    target = validate_database_target(allowed_environments=frozenset({'local', 'staging', 'test'}))
except TargetRefused as error:
    raise SystemExit(f'target_refused: {error}') from error

with psycopg.connect(target.database_url) as connection:
    with connection.cursor() as cursor:
        cursor.execute(
            "select current_database(), current_user, "
            "coalesce(inet_server_addr()::text, 'local-socket'), inet_server_port()"
        )
        database, database_user, server_address, server_port = cursor.fetchone()

result = target.sanitized()
result.update({
    'connected_database': database,
    'database_user': database_user,
    'server_address': server_address,
    'server_port': server_port,
})
print(json.dumps(result, sort_keys=True))
