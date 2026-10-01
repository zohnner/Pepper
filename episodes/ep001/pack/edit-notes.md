# ep001 — Edit Notes (for CapCut)

## Rough cut (2026-10-01, supersedes all earlier renders)
- `pack/rough-cut.mp4`: **30.0s**, 1080×1920, 30fps, H.264/AAC, faststart.
- Built by `tools/assemble-rough-cut.sh`, which now trims every numbered
  clip to its narrative beat derived from `captions.srt`
  (clip i ↔ caption i+1): 6.0 + 5.0 + 6.0 + 5.0 + 4.5 + 3.5 tail.
- Captions are burned in from a generated `captions.ass` (explicit
  1080×1920 script resolution — burning the raw SRT made libass fall back
  to 384×288 and rendered giant captions at the top; fixed).
- Voiceover (27.552s) runs 00:00–00:27.6, then ~2.4s of silence under the
  crank end card. Generated clips' embedded audio is discarded.
- The earlier 60s concat render (full 10s clips, captions drifting off-beat)
  is superseded and must not be published.
- Frame-verified 2026-10-01: every beat shows the matching visual with the
  matching caption (t=3/8/14/19/24/28).

## Structure
- 6 clips, trimmed to beats above. Total 30s.
- Voiceover runs 00:00–00:27.6, then silence under the crank end card (05.mp4).

## Audio/visual alignment (fixed 2026-10-01)
The hook is its own visual beat (00.mp4). Every narration line now lands on its matching shot:
| Time | Audio | Visual |
|---|---|---|
| 00:00–06 | "Marlow says I owe him forty-seven cranks…" | 00.mp4 chains + crank + paw |
| 00:06–11 | "I woke up underground…" | 01.mp4 puddle / Nib |
| 00:11–17 | "The kid's name is Nib…" | 02.mp4 market |
| 00:17–22 | "Then the possum showed me the lift…" | 03.mp4 Marlow / key |
| 00:22–26.5 | "Twelve chains. I counted…" | 04.mp4 lift shaft |
| 00:26.5–30 | silence | 05.mp4 paw on crank (the button) |

## Open review items for Zohn (not blocking the pipeline)
- Shot 03 (Marlow beat): visual centers on Marlow + a key; narration says
  "the possum showed me the lift." Optional regen: Marlow gesturing toward
  the lift shaft mechanism.
- Shot 01: eyeball Pepper's torn-ear notch in the puddle frames (drift check).
- Voiceover: judge whether Lily (avocado_v2) is too smooth/sultry vs dry/raspy.
  Backups on file: vdc_13188, vdc_NOID42.

## In CapCut
1. Import 01–05.mp4 in order + voiceover.mp3 on A1.
2. Captions: import captions.srt, or re-time with auto-captions and paste the text. Keep captions in the lower third, clear of platform UI (leave ~250px bottom margin) and Pepper's face.
3. Music bed: pick a trending dark-ambient sound, drop to ~−20dB under the voiceover. Silence it completely under 05.mp4 (the lift).
4. Cover frame: use the cover text below, burned in or as a text layer: "47 CRANKS. 12 CHAINS."
5. Export: 1080×1920, 30fps, high bitrate. No watermarks.

## Notes — STYLE-C RETRY (2026-10-01)
- This pack is the full style-C retry: all 5 stills regenerated in the locked "stylized 3D storybook
  noir" look (bible/style-lock.md), re-animated, pack rebuilt. Voiceover/captions/cover unchanged.
- Shot 4 got a FRESH vertical generation this time (no crop) — platform, chains, grate daylight,
  Pepper small at the edge. No fallback needed.
- All 5 stills passed the drift firewall: Pepper's four marks verified, style matched to the lock.
- The hook lands in the first 3 seconds: keep shot 1's opening frame punchy, no fade-in.
