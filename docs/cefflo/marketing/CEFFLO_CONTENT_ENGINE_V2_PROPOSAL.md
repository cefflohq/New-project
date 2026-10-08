# CEFFLO Content Engine V2 — n8n proposal

**Status:** APPROVED by Founder 2026-10-08. Implementation: `automation/n8n/content-engine-v2/`
(imported inactive into n8n.cefflo.com). No paid API connected yet.
**Date:** 2026-10-08
**Authority:** `CEFFLO_MARKETING_MASTER.md` (M1–M6, state machine §19–20),
`sot/marketing/02_CLAIMS_REGISTRY.md`, `sot/marketing/10_BRAND_VOICE_LANGUAGE_SYSTEM.md`,
`sot/10_PRICING.md`. Supersedes the inactive legacy
`automation/n8n/content-engine` stubs once approved.

## 1. Founder decisions (2026-10-08)

| Item | Decision |
|---|---|
| Orchestrator | n8n (existing `cefflo-n8n-new`, 127.0.0.1:5678). No Arcads. |
| Writer (M1/M2/M3, M5 text QA) | DeepSeek V4 Flash |
| Video | Seedance 2.5 (default image→video), Kling (fallback), OmniHuman (talking/lip-sync) |
| Image (keyframes) | Image model with reference-image support (character consistency) |
| Voice | ElevenLabs |
| Character | ONE AI brand ambassador, female, CEFFLO-owned persona |
| Approval channel | Telegram bot (Approve / Revise / Reject buttons) |
| Platforms | Video: TikTok, Facebook Reels, Instagram Reels · Text: Threads |
| Cadence | 5 items / day: 3 videos + 2 Threads text posts |
| Learning | Auto-recycle winners from analytics (Marketing Memory) |

## 2. Brand ambassador persona (fixed identity)

- Name: **Kak Zee** (Founder 2026-10-08). Founder creates the face/voice assets.
- Malay woman, mid-30s, runs her own small delivery business
  scenario; speaks Register B (natural everyday business Malay), never
  aku/kau, light English mixing for operational words (order, rider, zone).
- Fixed: reference image set (front, 3/4, profile, full body), wardrobe
  palette, one ElevenLabs voice ID, personality sheet. Stored in object
  storage; every generation uses the same references.
- Hard rules (Marketing Master "No fake testimony"):
  - She is a **brand ambassador / narrator**, never presented as a real
    customer; no usage history, revenue, savings or volume claims.
  - Every published video carries the platform's AI-generated label.

## 3. Daily mix (3 videos)

| Slot | Funnel | Formats |
|---|---|---|
| 1 | TOFU | POV / operational situation, micro-education, contrarian |
| 2 | TOFU or MOFU (alternating) | before/after workflow, objection answer |
| 3 | MOFU or BOFU | real product proof (screen recording), CTA "Download sekarang. Cuba percuma." |

Weekly ≈ 60% TOFU / 30% MOFU / 10% BOFU. BOFU and product-capability lines
only while the capability is LIVE in production (Claims Registry §3).

## 4. Workflow (n8n)

```
CRON 06:00 MYT ─► W1 Plan (M1+M2, DeepSeek)
                    reads Marketing Memory + winners + content history
                    → 3 Creative Briefs (funnel slot, angle, recycle-of?)
               ─► W2 Script (M3, DeepSeek)
                    hook, shot list (3–6s shots), VO lines, subtitles,
                    captions per platform, image/video prompts
               ─► W3 Text QA (M5, DeepSeek, separate prompt)
                    claims vs registry, language Q1–Q8, persona rules
                    FAIL → W2 once, then HOLD
               ─► W4 Produce (M4)
                    a. keyframes  (image model + persona references)
                    b. shots      (Seedance 2.5 → Kling fallback, 1 retry)
                    c. VO         (ElevenLabs, one file per line)
                    d. talking    (OmniHuman lip-sync for to-camera shots)
                    e. app screens (pre-recorded real captures library)
                    f. edit       (ffmpeg: assemble, subtitles, music,
                                   room tone, "phone look" preset §5)
               ─► W5 Media QA (M5)
                    frame sample check (hands/text/face drift), audio
                    loudness, duration, aspect, subtitle sync
               ─► W6 Telegram approval
                    preview video + caption + claims summary
                    [Approve] [Revise: note] [Reject]
                    no answer in 24h → HOLD (never auto-publish)
               ─► W7 Publish (M6) at scheduled slot
                    TikTok Content Posting API, Meta Graph API (FB+IG Reels)
                    AI label set; idempotent publish record
               ─► W8 Measure (M6) at +24h / +72h / +7d
                    views, 3s hold, completion, shares, saves, comments,
                    profile/link clicks → Performance Memory
               ─► W9 Learn + Recycle (M6→M1, weekly)
                    top performers → new variant (new hook / new world /
                    new format), never an identical repost; losers retired
W99 Error & recovery, cost guard (daily spend cap → PAUSED_SYSTEM_GUARD)
```

States follow Marketing Master §19 (NEW → … → CLOSED).

## 5. Realism presets

Generation prompts: "shot on phone, handheld, natural indoor light, slight
motion blur, real Malaysian shop/kitchen"; never "cinematic / 4K / studio".
Shots 3–6 s; avoid close hands, readable generated text, long talking takes.

ffmpeg "phone look" (final export): 1080×1920, 30 fps, H.264 ~6–8 Mbps,
light negative sharpen, film grain ~2–4%, micro handheld shake, mild warm/cool
white-balance drift, light vignette, room tone under VO, loudness −14 LUFS.

## 6. Voice presets (ElevenLabs)

One persona voice ID; stability ~35–45%, style ~10–20%; one line per
generation, best of 2–3 takes; audio tags for sighs/pauses where natural;
light EQ + compression + room tone. Scripts follow Brand Voice §4–§12
(short spoken lines, natural hesitation used sparingly).

## 7. Data & storage

- Postgres schema `cefflo_content_engine_v2` (n8n's Postgres): briefs,
  scripts, assets, qa_records, approvals, publications, metrics, learnings,
  costs. Migration proposed separately before apply.
- Media files: object storage bucket (private), signed URLs for Telegram
  preview.
- Secrets only in n8n's encrypted credential store.

## 8. Credentials needed

DeepSeek API key · Seedance (BytePlus ModelArk) key · Kling API key ·
OmniHuman access · image model key · ElevenLabs key + voice · Telegram bot
token + Founder chat ID · TikTok developer app (Content Posting API — needs
TikTok app review before public posting) · Meta app with Instagram/Facebook
publish permissions (needs Meta app review) · storage bucket.

## 9. Cost & safety controls

- Daily spend cap per provider; job stops at cap.
- Cost per video recorded (CPAC); weekly cost report to Telegram.
- Exact per-video cost is measured during the pilot — not estimated here.
- No ad spend (Paid Growth stays disabled).

## 10. Rollout

1. Approve this proposal.
2. Persona build: reference images + voice; Founder approves the face/voice.
3. Pilot (manual trigger, 3 videos, no publishing) → Founder review of
   realism, voice, cost.
4. Telegram approval + scheduled generation (still manual publish).
5. Platform publishing after TikTok/Meta app reviews pass.
6. Analytics + recycle loop.

Production launch gate: BOFU/product claims only after CEFFLO is live in
production and on the App Store / Google Play.
