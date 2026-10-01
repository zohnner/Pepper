# API Pricing — video & voice (checked 2026-10-01)

The rotation strategy: run free tiers across vendors, test each one on Pepper reproduction specifically, and let the winner earn the paid slot. Re-check prices before spending — this space moves weekly.

## Video — fal.ai per-second pricing (published)

| Model | $/sec | Notes |
|-------|-------|-------|
| LTX-2.3 Fast | $0.04 (1080p) | Cheapest decent quality |
| Veo 3.1 Lite | $0.05 | 8s max, 1080p |
| MiniMax H3 Max | $0.08 (768p) | **First 5 generations/day FREE, no subscription** |
| Kling v3 Standard | $0.084 audio-off / $0.126 audio-on (720p) | The default for simple push-ins |
| Gemini Omni Flash | $0.10 | Editing strengths, not our use case |
| Kling v3 Pro | $0.112 / $0.168 (1080p) | Step up when 720p isn't enough |
| Wan 3.0 | $0.20 (1080p) | 30s single takes |
| Veo 3.1 Standard | $0.20 off / $0.40 on (4K) | Premium tier |
| Kling O3 4K | $0.42 | Delivery-ready 4K, overkill for us |

Sources: fal.ai model pages and community price tracking, Sep 2026.

Replicate carries many of the same models but prices higher (Kling 3.0 ~$0.14/s vs $0.084/s on fal), so fal is the default API route.

## Free rotation candidates (video)

1. **MiniMax H3 Max via fal.ai** — 5 free generations/day, every day, no subscription. At ~20 clips/week needed, this alone covers a third of production free. Rotation priority #1.
2. **Hailuo direct free tier** — ~2–3 watermarked videos/day at 720p. Good for testing the aesthetic, not for publishing.
3. **Replicate trial credits** — one-time, burn on comparison tests.
4. **Built-in pipeline (current)** — $0, unlimited within reason. The baseline everything else must beat.

## Voice pricing

| Option | Cost | Fits Pepper? |
|--------|------|--------------|
| Built-in TTS (current) | $0 | Baseline |
| edge-tts (open library) | $0 unlimited | Real free fallback, decent voices |
| ElevenLabs Free | $0, 10k chars/mo (~10 min) | Covers ~1/3 of monthly need, non-commercial, watermarked |
| ElevenLabs Starter | $6/mo, 30k chars, commercial, instant voice clone | **Covers full month** (~29k chars at 14 eps/week) |

Pepper's voice load: 14 episodes × ~85 words ≈ 29k characters/month. Starter at $6/mo covers it exactly; it's also the cheapest tier with a commercial license and voice cloning — the voice lock matters more than the price here.

## Pepper's monthly math (paid scenario, 14 eps/week)

- Clip volume: 14 eps × 4 clips × ~6s ≈ 1,344 clip-seconds/month
- All-paid LTX-2.3 Fast: ~$54/mo
- All-paid Kling v3 Standard: ~$113/mo
- **H3 Max with daily freebies: ~$36/mo** (150 of ~224 clips free)
- Voice: $0–6/mo
- **Realistic paid total: $36–60/mo** once free tiers are exhausted

## Rotation protocol

1. Each week, generate the same 2 test shots (Pepper close-up + Drowned Mile wide) on every free candidate.
2. Score 1–5 on: Pepper's three marks intact, style match, motion quality, generation speed.
3. Log scores in `docs/vendor-tests.md` (create when rotation starts).
4. The upgrade trigger (from upgrade-path.md): a paid tool must save 2+ hrs/week or visibly lift retention. The test scores are the evidence.
5. Never upgrade during a good free run — spend only when free becomes the bottleneck.
