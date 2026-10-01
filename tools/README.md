# Tools

Helper scripts and checklists for the Pepper pipeline. Built as needed — smallest useful thing first.

## Planned

- `batch-tts.sh` — feed it the week's `voiceover.txt` files, get back audio per episode
- `new-episode.sh` — scaffold `episodes/epNNN/` from templates with the next number
- `continuity-check.md` — checklist: debt math, lift cranks, cast status before marking an episode done
- `post-checklist.md` — caption, hashtags, cover text, watermark check, schedule confirm

## Conventions

- Episode numbers are zero-padded: `ep001`, `ep002`, …
- Final assets live in `episodes/epNNN/assets/` as `shot1.mp4`, `shot2.mp4`, …, `voiceover.mp3`, `master.mp4`
- Never commit platform-watermarked exports to `assets/`
