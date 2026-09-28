import { resolveFrontendEnvironment } from './environment.mjs';

try {
  const target = resolveFrontendEnvironment(process.env);
  console.log(JSON.stringify({
    environment: target.name,
    projectRef: target.projectRef,
    supabaseOrigin: target.supabaseUrl,
    production: target.name === 'production'
  }, null, 2));
} catch (error) {
  console.error(`environment_refused: ${error.message}`);
  process.exitCode = 1;
}
