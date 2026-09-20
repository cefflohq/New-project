{{flutter_js}}
{{flutter_build_config}}

// This host is a Founder review surface, so every refresh must render the
// currently deployed bundle. A stale Flutter service worker previously kept
// serving an older Sign In screen after a successful preview deployment.
(async () => {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }

  // Flutter's build hash gives main.dart.js an immutable URL per build while
  // leaving the physical asset name unchanged for static hosting.
  const buildVersion = {{flutter_service_worker_version}};
  for (const build of _flutter.buildConfig.builds) {
    if (build.mainJsPath === 'main.dart.js') {
      build.mainJsPath = `main.dart.js?v=${buildVersion}`;
    }
  }

  await _flutter.loader.load();
})();
