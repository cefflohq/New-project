# CEFFLO --- PWA

## PW-00 Scope

Applies to Vendor/Rider and any other Cefflo PWA surface.

## PW-01 Mobile First

Primary UX is mobile-first, with strict attention to common phone
viewports.

## PW-02 Manifest

Verify correct name/icons/start URL/display/scope/theme metadata for
each installable PWA.

## PW-03 Service Worker

Service worker must not trap users on stale broken builds. Define cache
strategy by asset/data type.

## PW-04 Version Updates

Normal product updates should reach users through refresh/version
detection without routine maintenance mode. Define outdated-client
behaviour and coordinate with FOUNDR Client Version Control.

## PW-05 Offline/Network

Do not pretend full offline support if unavailable. Provide explicit
degraded/error/retry states for relevant workflows.

## PW-06 Data

Do not cache sensitive/authenticated data insecurely. Avoid unnecessary
PII in local storage.

## PW-07 Deployment

Coordinate service-worker/cache invalidation with Vercel release and
rollback.

## PW-08 Rider Device Capabilities

Current Rider PWA may have limits for background
GPS/camera/push/offline. Do not expand Stage 4 into native Flutter
unless approved.

## PW-09 Regression

Test installability, refresh/update, navigation, stale client behaviour,
network interruption and relevant viewport behaviour.

## PW-10 Stage 4 Gate

Required PWAs install/run/update predictably and fail gracefully under
realistic network conditions.
