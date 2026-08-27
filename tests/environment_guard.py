"""Fail-closed environment identity checks for Cefflo database tooling."""

from __future__ import annotations

import ipaddress
import os
import re
from dataclasses import dataclass
from typing import Mapping
from urllib.parse import unquote, urlparse

PRODUCTION_PROJECT_REF = "lmaxtrubwdniovxyuqdy"
NON_PRODUCTION_ENVIRONMENTS = frozenset({"local", "preview", "staging", "test"})
HOSTED_REF_PATTERN = re.compile(r"^[a-z0-9]{20}$")


class TargetRefused(RuntimeError):
    """Raised before connection when a target is not positively safe."""


@dataclass(frozen=True)
class DatabaseTarget:
    environment: str
    project_ref: str
    database_url: str
    host: str
    port: int
    database: str
    mutating: bool
    supabase_url: str | None

    def sanitized(self) -> dict[str, object]:
        return {
            "environment": self.environment,
            "project_ref": self.project_ref,
            "database_host": self.host,
            "database_port": self.port,
            "database_name": self.database,
            "mutating": self.mutating,
            "supabase_origin": self.supabase_url,
        }


def _required(values: Mapping[str, str], name: str) -> str:
    value = str(values.get(name, "")).strip()
    if not value:
        raise TargetRefused(f"{name} is required")
    return value


def _is_loopback(host: str) -> bool:
    if host.lower() == "localhost":
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def _validate_supabase_url(raw_url: str, environment: str, project_ref: str) -> str:
    parsed = urlparse(raw_url)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise TargetRefused("SUPABASE_URL must be a valid absolute HTTP(S) URL")
    if parsed.username or parsed.password or parsed.path not in {"", "/"} or parsed.query or parsed.fragment:
        raise TargetRefused("SUPABASE_URL must be an origin without credentials, path, query, or fragment")

    host = parsed.hostname.lower()
    if environment == "local":
        if not _is_loopback(host):
            raise TargetRefused("local SUPABASE_URL must use a loopback host")
    else:
        if host == f"{PRODUCTION_PROJECT_REF}.supabase.co":
            raise TargetRefused("known Production Supabase URL is forbidden")
        if parsed.scheme != "https" or host != f"{project_ref}.supabase.co":
            raise TargetRefused("SUPABASE_URL does not positively match CEFFLO_SUPABASE_PROJECT_REF")
    return f"{parsed.scheme}://{parsed.netloc}"


def validate_database_target(
    values: Mapping[str, str] | None = None,
    *,
    mutating: bool = False,
    allowed_environments: frozenset[str] = NON_PRODUCTION_ENVIRONMENTS,
) -> DatabaseTarget:
    values = os.environ if values is None else values
    environment = _required(values, "CEFFLO_ENVIRONMENT").lower()
    project_ref = _required(values, "CEFFLO_SUPABASE_PROJECT_REF").lower()
    database_url = _required(values, "DATABASE_URL")

    if environment not in allowed_environments:
        raise TargetRefused(f"environment {environment!r} is not approved for this command")
    if environment == "production" or project_ref == PRODUCTION_PROJECT_REF:
        raise TargetRefused("known Production Supabase project is forbidden")

    parsed = urlparse(database_url)
    if parsed.scheme not in {"postgres", "postgresql"}:
        raise TargetRefused("DATABASE_URL must use postgres or postgresql")
    if not parsed.hostname or not parsed.path or parsed.path == "/":
        raise TargetRefused("DATABASE_URL must include a host and database name")
    try:
        port = parsed.port or 5432
    except ValueError as error:
        raise TargetRefused("DATABASE_URL contains an invalid port") from error

    host = parsed.hostname.lower()
    username = unquote(parsed.username or "").lower()
    database = unquote(parsed.path.removeprefix("/"))

    if PRODUCTION_PROJECT_REF in host or PRODUCTION_PROJECT_REF in username:
        raise TargetRefused("known Production Supabase database identity is forbidden")

    if environment == "local":
        if project_ref != "local":
            raise TargetRefused("local database commands require CEFFLO_SUPABASE_PROJECT_REF=local")
        if not _is_loopback(host):
            raise TargetRefused("local database commands require a loopback DATABASE_URL")
        if port != 54322:
            raise TargetRefused("local database commands require the configured local database port 54322")
        raw_supabase_url = str(values.get("SUPABASE_URL", "")).strip()
        supabase_url = _validate_supabase_url(raw_supabase_url, environment, project_ref) if raw_supabase_url else None
    else:
        if not HOSTED_REF_PATTERN.fullmatch(project_ref):
            raise TargetRefused("hosted targets require a 20-character Supabase project ref")
        supabase_url = _validate_supabase_url(_required(values, "SUPABASE_URL"), environment, project_ref)
        direct_match = host == f"db.{project_ref}.supabase.co"
        pooler_match = host.endswith(".pooler.supabase.com") and username.endswith(f".{project_ref}")
        identity_matches = direct_match or pooler_match
        if not identity_matches:
            raise TargetRefused("DATABASE_URL does not positively match CEFFLO_SUPABASE_PROJECT_REF")

    if mutating:
        if values.get("CEFFLO_DISPOSABLE_TARGET") != "1":
            raise TargetRefused("CEFFLO_DISPOSABLE_TARGET=1 is required for mutation")
        if values.get("CEFFLO_ALLOW_MUTATING_TESTS") != "1":
            raise TargetRefused("CEFFLO_ALLOW_MUTATING_TESTS=1 is required for mutation")

    return DatabaseTarget(environment, project_ref, database_url, host, port, database, mutating, supabase_url)
