import os
import subprocess
import unittest

from tests.environment_guard import PRODUCTION_PROJECT_REF, TargetRefused, validate_database_target


LOCAL = {
    'CEFFLO_ENVIRONMENT': 'local',
    'CEFFLO_SUPABASE_PROJECT_REF': 'local',
    'DATABASE_URL': 'postgresql://postgres:postgres@127.0.0.1:54322/postgres',
    'CEFFLO_DISPOSABLE_TARGET': '1',
    'CEFFLO_ALLOW_MUTATING_TESTS': '1',
}
HOSTED_REF = 'abcdefghijklmnopqrst'
OTHER_HOSTED_REF = 'zyxwvutsrqponmlkjihg'
HOSTED_STAGING = {
    'CEFFLO_ENVIRONMENT': 'staging',
    'CEFFLO_SUPABASE_PROJECT_REF': HOSTED_REF,
    'SUPABASE_URL': f'https://{HOSTED_REF}.supabase.co',
    'DATABASE_URL': f'postgresql://postgres:secret@db.{HOSTED_REF}.supabase.co:5432/postgres',
    'CEFFLO_DISPOSABLE_TARGET': '1',
    'CEFFLO_ALLOW_MUTATING_TESTS': '1',
}
HOSTED_TEST = {
    **HOSTED_STAGING,
    'CEFFLO_ENVIRONMENT': 'test',
    'DATABASE_URL': f'postgresql://postgres.{HOSTED_REF}:secret@aws-0-test.pooler.supabase.com:5432/postgres',
}


class DatabaseEnvironmentGuardTests(unittest.TestCase):
    def assert_refused(self, values, *, mutating=False, allowed_environments=None):
        options = {'mutating': mutating}
        if allowed_environments is not None:
            options['allowed_environments'] = allowed_environments
        with self.assertRaises(TargetRefused):
            validate_database_target(values, **options)

    def test_accepts_explicit_disposable_local_mutation(self):
        target = validate_database_target(LOCAL, mutating=True)
        self.assertEqual(target.project_ref, 'local')
        self.assertTrue(target.mutating)

    def test_accepts_valid_hosted_staging_identity(self):
        target = validate_database_target(HOSTED_STAGING, mutating=True)
        self.assertEqual(target.environment, 'staging')
        self.assertEqual(target.project_ref, HOSTED_REF)

    def test_accepts_valid_hosted_test_identity(self):
        target = validate_database_target(HOSTED_TEST, mutating=True)
        self.assertEqual(target.environment, 'test')
        self.assertEqual(target.project_ref, HOSTED_REF)

    def test_refuses_missing_identity(self):
        self.assert_refused({'DATABASE_URL': LOCAL['DATABASE_URL']})

    def test_refuses_malformed_database_url(self):
        self.assert_refused({**LOCAL, 'DATABASE_URL': 'not-a-url'}, mutating=True)

    def test_refuses_malformed_hosted_project_ref(self):
        self.assert_refused({**HOSTED_STAGING, 'CEFFLO_SUPABASE_PROJECT_REF': 'not-a-ref'}, mutating=True)

    def test_refuses_non_loopback_local_target(self):
        self.assert_refused({**LOCAL, 'DATABASE_URL': 'postgresql://postgres:password@db.example.test:54322/postgres'}, mutating=True)

    def test_refuses_wrong_local_port(self):
        self.assert_refused({**LOCAL, 'DATABASE_URL': 'postgresql://postgres:postgres@127.0.0.1:5432/postgres'}, mutating=True)

    def test_refuses_production_environment(self):
        self.assert_refused({
            **HOSTED_STAGING,
            'CEFFLO_ENVIRONMENT': 'production',
            'CEFFLO_SUPABASE_PROJECT_REF': PRODUCTION_PROJECT_REF,
            'SUPABASE_URL': f'https://{PRODUCTION_PROJECT_REF}.supabase.co',
            'DATABASE_URL': f'postgresql://postgres.{PRODUCTION_PROJECT_REF}:secret@aws-0-test.pooler.supabase.com:5432/postgres',
        }, mutating=True)

    def test_refuses_production_ref_disguised_as_test(self):
        self.assert_refused({
            **HOSTED_TEST,
            'CEFFLO_SUPABASE_PROJECT_REF': PRODUCTION_PROJECT_REF,
            'SUPABASE_URL': f'https://{PRODUCTION_PROJECT_REF}.supabase.co',
            'DATABASE_URL': f'postgresql://postgres.{PRODUCTION_PROJECT_REF}:secret@aws-0-test.pooler.supabase.com:5432/postgres',
        }, mutating=True)

    def test_refuses_production_url_with_nonproduction_declared_ref(self):
        self.assert_refused({**HOSTED_STAGING, 'SUPABASE_URL': f'https://{PRODUCTION_PROJECT_REF}.supabase.co'}, mutating=True)

    def test_refuses_production_database_hostname_with_nonproduction_declared_ref(self):
        self.assert_refused({
            **HOSTED_STAGING,
            'DATABASE_URL': f'postgresql://postgres:secret@db.{PRODUCTION_PROJECT_REF}.supabase.co:5432/postgres',
        }, mutating=True)

    def test_refuses_production_database_username_with_nonproduction_declared_ref(self):
        self.assert_refused({
            **HOSTED_STAGING,
            'DATABASE_URL': f'postgresql://postgres.{PRODUCTION_PROJECT_REF}:secret@aws-0-test.pooler.supabase.com:5432/postgres',
        }, mutating=True)

    def test_refuses_declared_ref_vs_database_url_mismatch(self):
        self.assert_refused({
            **HOSTED_STAGING,
            'DATABASE_URL': f'postgresql://postgres.{OTHER_HOSTED_REF}:secret@aws-0-test.pooler.supabase.com:5432/postgres',
        }, mutating=True)

    def test_refuses_declared_ref_vs_supabase_url_mismatch(self):
        self.assert_refused({**HOSTED_STAGING, 'SUPABASE_URL': f'https://{OTHER_HOSTED_REF}.supabase.co'}, mutating=True)

    def test_refuses_hosted_target_without_supabase_url(self):
        values = {**HOSTED_STAGING}
        values.pop('SUPABASE_URL')
        self.assert_refused(values, mutating=True)

    def test_refuses_ambiguous_pooler_identity(self):
        self.assert_refused({
            **HOSTED_STAGING,
            'DATABASE_URL': f'postgresql://postgres.{HOSTED_REF}:secret@database.example.test:5432/postgres',
        }, mutating=True)

    def test_refuses_mutation_without_disposable_flag(self):
        values = {**LOCAL}
        values.pop('CEFFLO_DISPOSABLE_TARGET')
        self.assert_refused(values, mutating=True)

    def test_refuses_mutation_without_opt_in(self):
        values = {**LOCAL}
        values.pop('CEFFLO_ALLOW_MUTATING_TESTS')
        self.assert_refused(values, mutating=True)

    def test_refuses_hosted_mutation_without_disposable_flag(self):
        values = {**HOSTED_STAGING}
        values.pop('CEFFLO_DISPOSABLE_TARGET')
        self.assert_refused(values, mutating=True)

    def test_refuses_hosted_mutation_without_opt_in(self):
        values = {**HOSTED_TEST}
        values.pop('CEFFLO_ALLOW_MUTATING_TESTS')
        self.assert_refused(values, mutating=True)

    def test_refuses_preview_mutation(self):
        self.assert_refused(
            {**HOSTED_STAGING, 'CEFFLO_ENVIRONMENT': 'preview'},
            mutating=True,
            allowed_environments=frozenset({'local', 'staging', 'test'}),
        )


class FrontendEnvironmentGuardTests(unittest.TestCase):
    def run_check(self, values):
        environment = os.environ.copy()
        for name in ('CEFFLO_ENVIRONMENT', 'CEFFLO_SUPABASE_PROJECT_REF', 'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY'):
            environment.pop(name, None)
        environment.update(values)
        return subprocess.run(
            ['node', 'scripts/check-environment.mjs'],
            cwd=os.path.dirname(os.path.dirname(__file__)),
            env=environment,
            capture_output=True,
            text=True,
            check=False,
        )

    def assert_frontend_accepted(self, environment):
        result = self.run_check(environment)
        self.assertEqual(result.returncode, 0, result.stderr)

    def assert_frontend_refused(self, environment):
        result = self.run_check(environment)
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_accepts_explicit_local_frontend(self):
        self.assert_frontend_accepted({
            'CEFFLO_ENVIRONMENT': 'local',
            'CEFFLO_SUPABASE_PROJECT_REF': 'local',
            'SUPABASE_URL': 'http://127.0.0.1:54321',
            'SUPABASE_PUBLISHABLE_KEY': 'local-public-key',
        })

    def test_accepts_synthetic_hosted_staging_frontend(self):
        self.assert_frontend_accepted({
            'CEFFLO_ENVIRONMENT': 'staging',
            'CEFFLO_SUPABASE_PROJECT_REF': HOSTED_REF,
            'SUPABASE_URL': f'https://{HOSTED_REF}.supabase.co',
            'SUPABASE_PUBLISHABLE_KEY': 'synthetic-public-key',
        })

    def test_accepts_synthetic_hosted_test_frontend(self):
        self.assert_frontend_accepted({
            'CEFFLO_ENVIRONMENT': 'test',
            'CEFFLO_SUPABASE_PROJECT_REF': HOSTED_REF,
            'SUPABASE_URL': f'https://{HOSTED_REF}.supabase.co',
            'SUPABASE_PUBLISHABLE_KEY': 'synthetic-public-key',
        })

    def test_refuses_missing_frontend_identity(self):
        self.assert_frontend_refused({})

    def test_refuses_malformed_frontend_project_ref(self):
        self.assert_frontend_refused({
            'CEFFLO_ENVIRONMENT': 'staging',
            'CEFFLO_SUPABASE_PROJECT_REF': 'not-a-ref',
            'SUPABASE_URL': 'https://not-a-ref.supabase.co',
            'SUPABASE_PUBLISHABLE_KEY': 'synthetic-public-key',
        })

    def test_refuses_production_ref_for_preview(self):
        self.assert_frontend_refused({
            'CEFFLO_ENVIRONMENT': 'preview',
            'CEFFLO_SUPABASE_PROJECT_REF': PRODUCTION_PROJECT_REF,
            'SUPABASE_URL': f'https://{PRODUCTION_PROJECT_REF}.supabase.co',
            'SUPABASE_PUBLISHABLE_KEY': 'public-key',
        })

    def test_refuses_production_url_with_nonproduction_frontend_ref(self):
        self.assert_frontend_refused({
            'CEFFLO_ENVIRONMENT': 'staging',
            'CEFFLO_SUPABASE_PROJECT_REF': HOSTED_REF,
            'SUPABASE_URL': f'https://{PRODUCTION_PROJECT_REF}.supabase.co',
            'SUPABASE_PUBLISHABLE_KEY': 'public-key',
        })

    def test_refuses_mismatched_hosted_frontend_identity(self):
        self.assert_frontend_refused({
            'CEFFLO_ENVIRONMENT': 'staging',
            'CEFFLO_SUPABASE_PROJECT_REF': HOSTED_REF,
            'SUPABASE_URL': f'https://{OTHER_HOSTED_REF}.supabase.co',
            'SUPABASE_PUBLISHABLE_KEY': 'public-key',
        })


if __name__ == '__main__':
    unittest.main()
