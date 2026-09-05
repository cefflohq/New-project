# Cefflo Vendor Flutter Prototype

A pure Flutter/Dart reconstruction of the Founder-approved Cefflo Vendor
prototype. It covers the complete V-01 through V-60 scene map using reusable
mobile components and one global Roboto type family.

This remains an isolated UX prototype:

- all data and interaction state are local and temporary;
- no Supabase, API, authentication, persistence, or production route is wired;
- reconciliation and subscription/payment scenes retain their explicit HOLD
  boundaries from the canonical 60-screen master.

The Android and Flutter Web targets render the same Dart widget tree. The web
build exists only to make Founder review easy in a browser.
