-- CEFFLO read-only schema inspection (G2). Environment-agnostic.
-- Run ONLY through run-readonly-inspection.sh, which forces a read-only
-- transaction. Output is deterministic and sorted so two environments can
-- be diffed line by line (staging baseline vs Production).
\pset format unaligned
\pset tuples_only on
\pset fieldsep '|'
begin transaction read only;
set local statement_timeout = '60s';

\echo '## migrations'
select 'migration|' || version from supabase_migrations.schema_migrations order by version;

\echo '## extensions'
select 'extension|' || extname from pg_extension order by extname;
select 'available_extension|pg_cron|' || (count(*) > 0)::text from pg_available_extensions where name = 'pg_cron';

\echo '## cron jobs (only if pg_cron is installed)'
select 'cron_present|' || (to_regclass('cron.job') is not null)::text;

\echo '## tables and columns (public)'
select 'column|' || table_name || '.' || column_name || '|' || data_type || '|' || is_nullable
from information_schema.columns where table_schema = 'public' order by table_name, column_name;

\echo '## functions (public)'
select 'function|' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')|secdef=' || p.prosecdef
from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' order by 1;

\echo '## function grants to anon/authenticated'
select 'grant|' || routine_name || '|' || grantee from information_schema.role_routine_grants
where routine_schema = 'public' and grantee in ('anon', 'authenticated') order by 1;

\echo '## RLS enabled'
select 'rls|' || c.relname || '|' || c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' order by c.relname;

\echo '## policies'
select 'policy|' || tablename || '|' || policyname || '|' || cmd || '|' || array_to_string(roles, ',')
from pg_policies where schemaname in ('public', 'storage') order by 1;

\echo '## triggers (public)'
select 'trigger|' || event_object_table || '|' || trigger_name from information_schema.triggers
where trigger_schema = 'public' group by 1 order by 1;

\echo '## storage buckets'
select 'bucket|' || id || '|public=' || public from storage.buckets order by id;

\echo '## row counts that matter for the release (counts only, no data)'
select 'count|orders|' || count(*) from public.orders;
select 'count|businesses|' || count(*) from public.businesses;
select 'count|riders|' || count(*) from public.riders;
select 'count|auth_users|' || count(*) from auth.users;
select 'count|storage_objects_by_bucket|' || coalesce(bucket_id, '-') || '|' || count(*) from storage.objects group by bucket_id order by 1;

rollback;
