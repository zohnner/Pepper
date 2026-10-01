# Tools

The Pepper pipeline. One command builds an episode pack; the runbook covers
the agent-driven half (stills + animation).

## The pipeline

```
beats.yaml  →  voiceover  →  word-aligned captions  →  rough cut  →  push
```

- **`build-episode.sh <ep> [--push] [--skip-voice] [--skip-caps]`** — the
  one-command pack builder. Preflight (clips present, debt chains), TTS
  voiceover in the locked voice, faster-whisper word-accurate captions,
  drift review sheet, edit notes, beat-trimmed assembly with the debt HUD,
  duration check. `--push` uploads to GitHub (do it after the drift eyeball).
- **`episode-runbook.md`** — what the agent does before the script: stills
  via `media.generate_image` (reference-chained), the drift gate, animation
  via `media.generate_video`, then handoff to build-episode.sh.
- **`make-captions.py`** — `beats.yaml` + `voiceover.mp3` → `captions.srt`
  with word-accurate timings (faster-whisper, base model, CPU). Also
  generates the TTS input text (`voiceover-txt`), and prints the locked
  voice (`voice`) and beat shot list (`shots`).
- **`assemble-rough-cut.sh <pack>`** — trims each clip to its caption beat,
  burns in captions (1080×1920 PlayRes ASS), burns the debt-counter HUD when
  `pack/debt.json` exists, mixes voiceover.
- **`push-pack.py <ep> "<msg>" [--tools] [--dry-run]`** — pushes the pack
  (and optionally all of tools/) to zohnner/Pepper via the Contents API.
- **`drift-contact-sheet.py <ep>`** — `pack/drift-review.jpg`: model sheet +
  marks detail on top, every still labeled below; appends blank-verdict rows
  to `drift-log.csv` for the 2-minute human gate.
- **`new-episode.sh`** — scaffold `episodes/epNNN/` (script, prompts, meta,
  beats.yaml, pack/) from templates.

## Specs (built)

- `debt-counter-spec.md` — implemented in assemble-rough-cut.sh behind
  `pack/debt.json` (`{start, end, tick_at}`; `"lift"` = final shot).
  Amber ◈ counter top-left, ticks at the debt beat, flashes red 1s if debt
  went up. Click SFX not yet sourced — visual tick only.
- `drift-firewall-spec.md` — harness built (contact sheet + drift-log.csv);
  verdicts stay human until 20 consecutive model/human agreements.

## Checklists

- `continuity-check.md` — run before marking a script done; the log is law.
- `post-checklist.md` — caption, hashtags, cover, watermark, schedule.
- `capcut-template.md` — Zohn's 15-minute polish pass.

## Conventions

- Episode numbers are zero-padded: `ep001`, `ep002`, …
- `beats.yaml` is the single source of truth for narration; `voiceover.txt`
  is derived from it. Never hand-write `captions.srt` — generate it.
- Final assets live in `episodes/epNNN/assets/`; the shippable pack
  (`NN.mp4` clips, `voiceover.mp3`, `captions.srt`, `rough-cut.mp4`) in
  `episodes/epNNN/pack/`.
- Never commit platform-watermarked exports to `assets/`.
- Python env for the ML bits: `~/workspace/.venvs/pepper` (faster-whisper).
