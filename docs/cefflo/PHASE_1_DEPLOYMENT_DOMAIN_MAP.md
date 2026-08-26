# Phase 1 Deployment, Domain & Production Source Map

Status: P1.3 audit deliverable — Founder review required

Audit date: 2026-08-26

Repository baseline: `main` at `ee9e1fe35e654367fac280127818d41b854d4fa7` (`Document Phase 1 active legacy classification`)

Scope: read-only repository, GitHub, public DNS/TLS/HTTP, and available deployment-metadata inspection

## 1. Evidence boundary

This document records observed state; it does not treat intended architecture or repository configuration as proof of a live production route.

Evidence used:

- repository files and Git history at `/home/cefflo/New-project`;
- GitHub repository, commit-status, deployment, and environment metadata available to the authenticated `cefflohq` account;
- authoritative and public DNS responses;
- public HTTP and TLS probes of Cefflo hostnames and the latest Vercel deployment URL;
- [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [13_VERCEL.md](13_VERCEL.md), [14_CLOUDFLARE.md](14_CLOUDFLARE.md), [15_PWA.md](15_PWA.md), [PHASE_1_REPOSITORY_INVENTORY.md](PHASE_1_REPOSITORY_INVENTORY.md), and [PHASE_1_ACTIVE_LEGACY_CLASSIFICATION.md](PHASE_1_ACTIVE_LEGACY_CLASSIFICATION.md).

No Vercel CLI installation, local `.vercel/` link, Vercel access token, Cloudflare access token, Wrangler configuration, or Cloudflare CLI session was available. Provider-private project settings, alias assignments, environment values, and Cloudflare zone metadata are therefore `UNKNOWN / NEEDS AUDIT` unless independently observable through public or GitHub evidence.

Status vocabulary follows [04_CURRENT_STATE.md](04_CURRENT_STATE.md): `VERIFIED DONE`, `PARTIAL`, `MISSING`, `BLOCKED`, `FUTURE`, `DECISION REQUIRED`, and `UNKNOWN / NEEDS AUDIT`.

## 2. Surface → Domain → DNS → Vercel → Git commit map

| Surface | Intended hostname | Public DNS on 2026-08-26 | Proxy / HTTPS observation | Observed destination or origin | Vercel / Git evidence | Current availability | Classification |
|---|---|---|---|---|---|---|---|
| Marketing | `cefflo.com` | `A 2.57.91.91`; authoritative nameservers `nova.dns-parking.com` and `cosmos.dns-parking.com` | No Cloudflare evidence. HTTP returns `200` from `hcdn`; HTTPS fails before presenting a certificate | Hostinger parked-domain page | No root-host rewrite in `vercel.json`; no marketing implementation in the static build | Parked page only; canonical Cefflo marketing surface unavailable | `MISSING` / `BLOCKED` |
| Vendor | `vendor.cefflo.com` | Authoritative `NXDOMAIN` | Proxy not applicable; HTTPS unavailable because the hostname does not resolve | None publicly reachable | `vercel.json` maps this host to `/vendor`; latest Vercel GitHub deployment succeeded for current SHA | Unavailable on intended hostname | `MISSING` / `BLOCKED` |
| Rider | `rider.cefflo.com` | Authoritative `NXDOMAIN` | Proxy not applicable; HTTPS unavailable because the hostname does not resolve | None publicly reachable | `vercel.json` maps this host to `/rider`; latest Vercel GitHub deployment succeeded for current SHA | Unavailable on intended hostname | `MISSING` / `BLOCKED` |
| Customer Tracking | `track.cefflo.com` | Authoritative `NXDOMAIN` | Proxy not applicable; HTTPS unavailable because the hostname does not resolve | None publicly reachable | `vercel.json` maps this host to `/customer`; latest Vercel GitHub deployment succeeded for current SHA | Unavailable on intended hostname | `MISSING` / `BLOCKED` |
| FOUNDR | `foundr.cefflo.com` | Authoritative `NXDOMAIN` | Proxy not applicable; HTTPS unavailable because the hostname does not resolve | None publicly reachable | No implementation, build output, or hostname rewrite exists | Unavailable | `MISSING` |
| API decision item | `api.cefflo.com` | Authoritative `NXDOMAIN` | Proxy not applicable; HTTPS unavailable because the hostname does not resolve | None publicly reachable | No repository route or deployable API surface; canonical documents make the hostname conditional on a dedicated gateway decision | Not expected to be operational before the architecture decision | `DECISION REQUIRED` |

The `NXDOMAIN` results were consistent between the authoritative nameservers and public resolvers `1.1.1.1` and `8.8.8.8`. `www.cefflo.com` is an observed CNAME to `cefflo.com` and serves the same parked page; it is not one of the canonical surface hostnames.

## 3. Vercel production-deployment evidence

GitHub records a successful deployment created by `vercel[bot]`:

| Field | Evidence-backed value | Status |
|---|---|---|
| Git repository | `https://github.com/cefflohq/New-project.git` | `VERIFIED DONE` |
| Local and remote source | local `main` and `origin/main` at `ee9e1fe35e654367fac280127818d41b854d4fa7` | `VERIFIED DONE` |
| GitHub deployment environment | `Production` | `VERIFIED DONE` |
| Latest deployment record | ID `6105722674`, created `2026-08-26T14:17:31Z`, status `success` | `VERIFIED DONE` |
| Deployed commit | `ee9e1fe35e654367fac280127818d41b854d4fa7` | `VERIFIED DONE` |
| Deployed branch | Deployment ref is the immutable commit SHA. That SHA is the tip of `main` and `origin/main`; exact Vercel `gitBranch` metadata was not available | `PARTIAL` |
| Vercel team / project | Dashboard target identifies team `cefflohq26-6353s-projects`, project `new-project` | `VERIFIED DONE` |
| Deployment URL | `new-project-c8t3s0nfd-cefflohq26-6353s-projects.vercel.app` | `VERIFIED DONE` |
| Public deployment access | URL redirects to Vercel SSO; deployment assets cannot be fetched anonymously | `BLOCKED` |
| Custom-domain aliases in Vercel | Provider-private metadata unavailable | `UNKNOWN / NEEDS AUDIT` |
| Vercel environment variables | Provider-private metadata unavailable | `UNKNOWN / NEEDS AUDIT` |

GitHub shows seven successful Vercel deployment records for recent commits, including `cf8da040bec18932a048d384fe74f9510a1566f8`, `11d2f41`, `3963d5b`, `6b39325`, `9d53aba`, and `9b18b62`. This proves deployment history exists; it does not prove that a prior deployment can be restored safely.

The GitHub deployment object names the environment `Production` while its `production_environment` field is false. This metadata inconsistency requires provider-side review before relying on the field for automation or governance.

## 4. Repository build and routing reconciliation

| Repository artifact | Verified behavior | Live reconciliation |
|---|---|---|
| `vercel.json` | Runs `npm run build`, publishes `dist`, enables clean URLs, and rewrites Vendor, Rider, and Tracking hostnames to their surface directories | Intended host routing is repository-defined, but all three intended DNS names are `NXDOMAIN`; Vercel alias state is unknown |
| `package.json` | `build` runs only `node scripts/build-static.mjs` | Matches the declared static-build model; provider-side override settings are unknown |
| `scripts/build-static.mjs` | Recreates `dist`; copies `vendor`, `rider`, `customer`, `shared`, and `.openai/hosting.json`; creates a root Vendor redirect and a static asset worker | GitHub confirms a successful deployment of the current SHA, but SSO prevents asset-by-asset comparison with the deployed output |
| `.openai/hosting.json` | Contains project ID `appgprj_6a7dfb5970888191b3b8989054705da0` and is copied into `dist` | Relationship between this hosting-project identifier and the observed Vercel project is not established by available evidence |
| Generated root `index.html` | Redirects relative requests to `./vendor/` | This is not a marketing site. `cefflo.com` currently reaches a Hostinger parking origin, not this output |
| Root-host routing | No `cefflo.com` host rewrite exists | Canonical marketing hostname has neither repository implementation nor observed deployment routing |
| FOUNDR routing | No build source or hostname rewrite exists | Consistent with the documented missing FOUNDR implementation, but not with a deployable Stage 4 surface |
| API routing | No deployable API gateway surface exists | Consistent with the canonical conditional-decision status |

### Canonical source conclusion

GitHub and Vercel metadata establish that the current canonical GitHub commit was successfully built/deployed by Vercel. They do **not** establish that the intended production domains serve that deployment. Public evidence establishes the opposite for current reachability: the root domain serves Hostinger parking, and all intended subdomains are absent from DNS.

Asset-level proof that the protected Vercel deployment exactly matches the repository build remains `BLOCKED`; following the deployment URL returns the Vercel login page rather than application assets. This is not evidence of a source mismatch.

## 5. Missing, stale, or misrouted hostnames

- `cefflo.com` is misrouted relative to canonical intent: its DNS and HTTP response lead to Hostinger parking, while the repository has no marketing build.
- `vendor.cefflo.com`, `rider.cefflo.com`, and `track.cefflo.com` are missing from authoritative DNS even though repository routing rules exist for them.
- `foundr.cefflo.com` is missing from DNS and has no repository implementation or routing rule.
- `api.cefflo.com` is missing from DNS and remains an explicit architecture decision rather than an implementation defect at this stage.
- No public DNS evidence connects any canonical Cefflo hostname to the observed Vercel deployment.
- Whether Vercel already holds any custom-domain alias without a corresponding DNS record is `UNKNOWN / NEEDS AUDIT`.

## 6. DNS, Cloudflare proxy, and SSL observations

- The authoritative nameservers are Hostinger DNS nameservers, not Cloudflare nameservers.
- The root `A` record points directly to `2.57.91.91`; responses identify `hcdn` and contain no observed Cloudflare headers.
- Based on public evidence, `cefflo.com` is not proxied by Cloudflare. The intended subdomains have no records, so proxy state is not applicable publicly.
- Authenticated Cloudflare zone state, historical records, pending-zone configuration, and account ownership remain `UNKNOWN / NEEDS AUDIT`.
- `cefflo.com` accepts HTTP and returns the parked page without redirecting to HTTPS.
- TLS negotiation for `cefflo.com` fails before a peer certificate is presented, so valid public HTTPS for the canonical root is `MISSING`.
- The intended subdomains cannot be tested for TLS because DNS returns `NXDOMAIN`.
- The protected Vercel deployment URL has a valid `*.vercel.app` certificate and HSTS, but that does not establish custom-domain certificate coverage.

## 7. PWA deployment and version observations

### Repository evidence

- Vendor and Rider each have a manifest, service worker, installable start URL/scope, and 192/512/maskable icons.
- `vercel.json` serves `/sw.js` with `Cache-Control: no-cache` and `Service-Worker-Allowed: /`; host rewrites are intended to expose each surface's worker at that path.
- Vendor and Rider service workers use static cache names (`cefflo-vendor-shell-v1` and the corresponding Rider v1 cache) rather than a commit-derived build version.
- The service-worker shell lists include the relevant configuration, adapter, shared client, and 192/512 icon assets. The maskable icon is manifest-referenced but not precached.
- Customer Tracking has no manifest or service worker, consistent with the current repository inventory.

### Live observations

- Vendor and Rider PWA installation and service-worker control cannot work on their intended hostnames while those hostnames are `NXDOMAIN`.
- The protected Vercel deployment prevents anonymous live verification of manifests, service-worker registration, cache names, or update behavior.
- No live deployed-version marker or commit SHA is exposed by the repository build, so a browser-visible PWA version cannot be reconciled to Git without fetching and hashing protected assets.
- Static cache names create a stale-shell risk across deployments unless every changed asset is reliably refreshed by the current network strategy.

Overall PWA status: repository implementation `PARTIAL`; production availability `BLOCKED`.

## 8. Environment separation

- `shared/config.js` contains one frontend Supabase project URL, publishable key, and POD bucket name.
- The static build copies that configuration unchanged and has no repository-defined preview/production substitution mechanism.
- `.env.example` documents variables but is not consumed by `scripts/build-static.mjs`.
- Vercel environment-variable values and environment-specific build overrides are `UNKNOWN / NEEDS AUDIT`.
- Available repository evidence therefore does not establish isolated preview and production backend configuration. If preview deployments use the same static bundle, they will use the same embedded frontend backend target.
- GitHub has a `Production` environment with no observed protection rules or deployment branch policy. Deployment governance may instead exist in Vercel, but that metadata was unavailable.

Classification: environment separation is `UNKNOWN / NEEDS AUDIT`, with a repository-evidenced single-target configuration risk.

## 9. Rollback visibility

- GitHub exposes multiple successful Vercel deployment records and immutable commit SHAs. This provides identifiable rollback candidates.
- Historical deployment URLs are visible, but the deployments are access-protected and were not modified or promoted during this audit.
- No repository runbook identifies an approved rollback owner, selection rule, domain promotion procedure, data-compatibility check, or post-rollback validation sequence.
- Provider-side retention, instant-rollback availability, and custom-domain reassignment controls are `UNKNOWN / NEEDS AUDIT`.

Classification: rollback evidence is `PARTIAL`; rollback readiness is not verified.

## 10. Stage 4 blockers

1. The root domain is parked at Hostinger and lacks working HTTPS.
2. Vendor, Rider, Tracking, and FOUNDR hostnames do not exist in authoritative DNS.
3. No canonical hostname is publicly connected to the successful Vercel deployment.
4. Vercel custom-domain, project-setting, environment-variable, and production-branch metadata require an authenticated provider audit.
5. Cloudflare is not authoritative for the observed public zone; any intended Cloudflare ownership, proxy, SSL, or WAF configuration requires an authenticated account audit and an explicit migration plan.
6. The marketing site and FOUNDR surface are absent from the repository build.
7. Asset-level live/source parity cannot be verified while the deployment is SSO-protected and the custom domains are unavailable.
8. Preview/production backend separation is not established; the repository contains a single static Supabase target.
9. Vendor and Rider PWA production behavior and update safety cannot be validated without a reachable production surface.
10. Rollback candidates are visible, but rollback procedure and provider capability are not verified.

## 11. Founder decisions required

| Decision | Why it is required before deployment remediation |
|---|---|
| Select authoritative DNS operating model | Public DNS is currently Hostinger-managed while the canonical target architecture describes Cloudflare. Ownership and migration sequencing must be explicit before any record changes |
| Confirm the intended Vercel production project and account ownership | GitHub points to team `cefflohq26-6353s-projects` / project `new-project`; authenticated settings and administrative ownership still require confirmation |
| Decide deployment-protection policy | The Vercel deployment is SSO-protected. Founder direction is needed on preview protection versus public production availability |
| Approve the custom-domain cutover sequence | Root, Vendor, Rider, Tracking, and later FOUNDR require a controlled DNS, alias, certificate, verification, and rollback order |
| Decide the interim root-domain behavior | Repository output redirects root traffic to Vendor, while canonical architecture requires a marketing site that is not implemented |
| Confirm environment-separation standard | Preview and production backend targets, secret ownership, and allowed frontend configuration must be defined before relying on deployment environments |
| Decide whether `api.cefflo.com` is needed | The hostname remains conditional; no DNS or gateway should be created without the gateway architecture decision |
| Approve rollback governance | Define rollback authority, candidate-selection criteria, database compatibility checks, and validation steps before production cutover |

These decisions authorize planning only. This audit performs no DNS, Cloudflare, Vercel, Supabase, application, deployment, or domain changes.

## 12. Recommended next review action

Founder review should first confirm DNS authority/ownership and the intended Vercel production project. With those facts established, P1.4 planning can define a non-destructive cutover and validation sequence without treating the currently parked or absent hostnames as an acceptable baseline.
