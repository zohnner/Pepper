# CapCut Template — one-time setup

Configure once, reuse for every episode. Every episode pack is built to drop straight into this.

## Project settings

- Aspect ratio: **9:16** (1080 × 1920)
- Frame rate: 30fps
- Background: black (never white — letterboxing must disappear into the shadows)

## What each episode pack contains

`episodes/epNNN/pack/` (also zipped as `epNNN-pack.zip`):
- `01.mp4` … `05.mp4` — scene clips, numbered in story order. Import in order, lay end to end.
- `voiceover.mp3` — full narration, one file. Drop on the audio track under the clips.
- `captions.srt` — import for exact captions (or use CapCut auto-captions and compare).
- `edit-notes.md` — shot-by-shot assembly: which clip, trim points, where each voiceover line lands, music cue.
- `cover.txt` — the 4-word cover text.

## Timeline assembly (same every episode)

1. Lay `01.mp4`–`05.mp4` on V1 in order, no gaps, no transitions (hard cuts only — the style is stark).
2. `voiceover.mp3` on A1, starting at 0:00.
3. Music bed on A2 at −20dB under narration; **mute it entirely under the final lift shot** (silence is the signature).
4. Captions: top-third of the lower half — clear of the right rail and bottom caption zone.
5. Cover: export a still of shot 1 for the platform cover, add cover text from `cover.txt`.

## Caption style (set once, save as preset)

- Bold condensed sans, white with soft black shadow
- 2 lines max, centered, lower-middle placement
- Popping word-by-word is fine; never let a caption cover Pepper's face

## Export

- 1080 × 1920, 30fps, high bitrate
- Export CLEAN from CapCut (no CapCut watermark, no TikTok watermark) — the same file posts to TikTok and Reels natively
