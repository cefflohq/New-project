# CEFFLO --- STAGE 4 ROADMAP

## R-00 Goal

Move Cefflo from current verified baseline to Stage 4 production-ready
operation.

## Phase 0 --- AI Workstation

Status: completed/verify in Current State. - R0.1 VPS + Ubuntu Desktop -
R0.2 Git/GitHub authentication + repo clone - R0.3 Codex
install/auth/sandbox - R0.4 ChatGPT Desktop + Android Remote - R0.5
Remote → repo → GitHub verification Gate: Founder can control Codex
remotely against canonical repo.

## Phase 1 --- Baseline & SOT Lock

Status: complete at the P1.7 baseline lock.

-   R1.1 Repository inventory
-   R1.2 Active vs legacy/duplicate file classification
-   R1.3 Current deployment/domain mapping
-   R1.4 Vendor/Rider/Tracking/FOUNDR/backend baseline audit
-   R1.5 Test/migration/config inventory
-   R1.6 Stage 4 gap report
-   R1.7 Baseline lock + Current State update Gate: authoritative
    implementation for every surface is known; no ambiguity about SOT.

Post-Phase-1 execution follows the approved dependency-aware 16-sprint
sequence in `PHASE_1_STAGE4_GAP_REPORT.md`, beginning with S4-01. The
Phase 2–7 sections below remain domain and release views; they must not
override the approved sprint dependencies, security gates, test gates or
protected-action approvals.

## Phase 2 --- Backend & Security Foundation

-   R2.1 Schema/migration audit
-   R2.2 Auth/business membership/rider access audit
-   R2.3 RLS/RPC/mutation controls
-   R2.4 Delivery lifecycle/data integrity
-   R2.5 Tracking token/rate-limit/public access
-   R2.6 POD storage/access
-   R2.7 Realtime/location contracts
-   R2.8 Security headers/secrets/environment review
-   R2.9 Backend negative/E2E verification Gate: backend/security
    contracts required for Stage 4 pass applicable tests. Production
    changes require protected approval.

## Phase 3 --- Vendor PWA

-   R3.1 Canonical Vendor baseline lock
-   R3.2 Onboarding/auth
-   R3.3 Dashboard/action hierarchy
-   R3.4 Orders/intake
-   R3.5 Delivery planning/batching/zones
-   R3.6 Rider team/invite/assignment
-   R3.7 Current deliveries/history/performance
-   R3.8 Sales/order-page Stage 4 scope
-   R3.9 Exceptions/offline/network states
-   R3.10 Vendor PWA/version/update behaviour
-   R3.11 Vendor regression gate Gate: approved Vendor Stage 4 scope
    works against canonical backend.

## Phase 4 --- Rider + Customer Tracking

### Rider

-   R4.1 Rider auth/team access
-   R4.2 Assignment/pickup
-   R4.3 Route/stops
-   R4.4 Status transitions
-   R4.5 POD
-   R4.6 Exceptions/offline/network \### Customer
-   R4.7 Tokenized tracking
-   R4.8 Status/ETA/progress
-   R4.9 POD display
-   R4.10 Rating \### Cross-app
-   R4.11 Vendor/Rider/Customer lifecycle consistency
-   R4.12 Regression gate Gate: one coherent delivery can progress
    end-to-end across all three surfaces.

## Phase 5 --- FOUNDR Command Center

-   R5.1 Founder Overview + Platform Health
-   R5.2 Vendors
-   R5.3 Riders
-   R5.4 Delivery Operations
-   R5.5 Platform Controls
-   R5.6 Maintenance Control
-   R5.7 Feature Flags
-   R5.8 Client Version Control
-   R5.9 Announcements/Emergency
-   R5.10 Developer Mode
-   R5.11 Admin Audit Log
-   R5.12 Integrations Health
-   R5.13 System Health & Security
-   R5.14 privileged-action confirmation/reason/audit Gate: Founder can
    operate, control and protect required Stage 4 platform functions.

## Phase 6 --- Integration & Release Candidate

-   R6.1 Full Vendor → Rider → Customer E2E
-   R6.2 Exception/negative paths
-   R6.3 Security regression
-   R6.4 Cross-app status consistency
-   R6.5 PWA/install/update/offline regression
-   R6.6 Browser/mobile viewport regression
-   R6.7 Performance/health checks
-   R6.8 Cloudflare/Vercel/Supabase integration health
-   R6.9 Backup/recovery/rollback readiness
-   R6.10 Stage 4 Release Candidate Gate: release candidate passes
    agreed Stage 4 acceptance criteria.

## Phase 7 --- Production & Go-Live

-   R7.1 Production environment inventory
-   R7.2 Domain/DNS/SSL verification
-   R7.3 Environment/secrets verification
-   R7.4 Production change/deployment plan
-   R7.5 Controlled deployment
-   R7.6 Production smoke tests
-   R7.7 Production E2E
-   R7.8 Monitoring/health verification
-   R7.9 Rollback verification
-   R7.10 Stage 4 Go-Live Gate Gate: Founder approves Stage 4 live
    status.

## R-08 External Integration Decision Checkpoints

Before Go-Live explicitly classify each as REQUIRED / IMPLEMENTED /
PARTIAL / FUTURE / DECISION REQUIRED: - SMS/OTP provider; -
transactional email; - payment/FPX integration; - analytics; - error
monitoring/alerting; - external logistics; - other third-party
integrations discovered during audit.

Do not implement merely because listed here.
