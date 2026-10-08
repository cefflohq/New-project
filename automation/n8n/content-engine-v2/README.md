# CEFFLO Content Engine V2 (n8n)

Founder-approved 2026-10-08 — see `docs/cefflo/marketing/CEFFLO_CONTENT_ENGINE_V2_PROPOSAL.md`.
Daily: **3 videos** (TikTok · FB Reels · IG Reels) + **2 Threads posts**, presented by **Kak Zee**
(AI brand ambassador, Malay woman mid-30s). n8n orchestrates; DeepSeek writes; Seedance/Kling/OmniHuman
generate video; ElevenLabs voices; the render worker assembles a phone-look MP4; the Founder approves on Telegram.

| Workflow | Does |
|---|---|
| 01 Daily Plan + Script + QA | 06:00 MYT: plan 5 items from learnings, write scripts, independent QA |
| 02 Video Production | per shot → 02b, then render worker assembles the final video |
| 02b Render Shot | VO (ElevenLabs) · screen clip · keyframe → Seedance (Kling fallback) · OmniHuman lip-sync |
| 03 Send for Approval | Telegram preview with Approve / Revise / Reject |
| 04 Approval Inbox | Telegram buttons + revise notes (Founder chat only) → schedule slot |
| 05 Revise | rewrite with the Founder note → QA → re-render / re-preview |
| 06 Publisher | every 10 min: due items → TikTok / IG Reels / FB Reels / Threads |
| 07 Metrics + Learning | hourly metrics (24h/72h/7d); Sunday 21:00 learnings + recycle winners + report |
| 99 Error Alert | Telegram on any error |

All workflows are imported **inactive** into n8n.cefflo.com.

## Setup (in order)

1. **Database** — apply `migrations/20261008_content_engine_v2.sql` to the n8n Postgres (schema `cefflo_ce2`).
2. **Credentials** in n8n (exact names; type in brackets):
   - `CE2 Postgres` (Postgres) — the n8n Postgres, schema `cefflo_ce2`
   - `CE2 Telegram Bot` (Telegram API) — bot from @BotFather
   - `CE2 DeepSeek` (Header Auth) — `Authorization: Bearer <key>`
   - `CE2 Seedance` (Header Auth) — BytePlus ModelArk `Authorization: Bearer <key>`
   - `CE2 Kling` — keys are set in node *Kling JWT + body* (needs `NODE_FUNCTION_ALLOW_BUILTIN=crypto` on n8n)
   - `CE2 OmniHuman` (Header Auth) · `CE2 Image` (Header Auth) · `CE2 ElevenLabs` (Header Auth: `xi-api-key: <key>`)
   - `CE2 Render` (Header Auth) — `Authorization: Bearer <RENDER_TOKEN>`
   - `CE2 TikTok` (Header Auth: `Authorization: Bearer <user access token>`) · `CE2 Meta` · `CE2 Threads` (Bearer tokens)
3. **Config** — every workflow has a `Config` Code node; set the same values in each:
   Telegram chat id, model ids, Kak Zee reference image URLs + ElevenLabs voice id, render worker URL, IG/FB/Threads ids.
4. **Render worker** — on a host with ffmpeg (libass) and a public HTTPS URL:
   `RENDER_TOKEN=… PUBLIC_BASE=https://render.cefflo.com node render-worker/server.mjs`, then
   `render-worker/make-screens.sh` (screen-clip library).
5. **Pilot** — run 01 manually; approve on Telegram; keep 06 inactive until the TikTok audit and Meta app review pass.
6. **Activate** 99 → 04 → 01 → 06 → 07.

Regenerate workflows after editing prompts: `node scripts/generate-workflows.mjs`, then re-import.

## Rules built in

- Kak Zee is a brand ambassador, never a real customer: no own numbers, savings or testimonials (Claims Registry).
- Natural Malaysian Malay Register B; no aku/kau; no corporate/AI words (Brand Voice).
- Nothing publishes without Telegram **Approve**; AI label on (`is_aigc` for TikTok; set Meta label where required).
- Daily budget cap stops generation; weekly cost in the Telegram report.
- BOFU / product-capability content only once CEFFLO is live in production and on the stores.
