# CEFFLO --- LOCKED DECISIONS

## D-01 Positioning

Cefflo = Operating System for Home-Based Food Businesses. Not primarily
marketplace/rider company/GrabFood-style delivery platform.

## D-02 Acquisition

Primary acquisition focus is vendors, not building a proprietary rider
network.

## D-03 Rider Model

Support vendor-owned/trusted rider teams.

## D-04 Customer Tracking

Tokenized customer tracking; no customer account required.

## D-05 Client Strategy

PWA-first for Stage 4. Future native Rider app does not block Stage 4
unless Founder explicitly changes scope.

## D-06 Code SOT

GitHub `main` is canonical code SOT unless explicitly superseded.

## D-07 Backend/Deployment

Supabase is current backend direction. Vercel is current web deployment
direction. Cloudflare is part of domain/edge planning where configured.

## D-08 Release Policy

Normal updates should not require maintenance mode. Maintenance is
emergency/exception only. Prefer low-activity release windows,
backward-compatible backend changes, health checks and rollback.

## D-09 Payments

Vendor-controlled direct payment direction; COD is not core; riders
should not handle Cefflo cash.

## D-10 Engineering Method

No patchwork final fixes. Use scoped clean/root-cause implementation. Do
not redesign/refactor unrelated working areas.

## D-11 AI Ownership

Codex is primary engineering executor and canonical code integrator.
Claude is optional UI/prototype/review/specialist support, not parallel
code SOT.

## D-12 Founder Authority

Founder approves protected production/security/billing/destructive
operations and final phase gates.

## D-13 Stage Discipline

Design future systems when useful, but build only when the current stage
needs them. Do not delay Stage 4 with later-stage
automation/native/regional features.

## D-14 UI Launch Review

Before calling Vendor/Rider UI launch-ready verify: 1. exception/error
states; 2. urgent action hierarchy; 3. cross-app lifecycle/status
consistency.

## D-15 Naming

Brand: Cefflo. Administrative command center: FOUNDR.
