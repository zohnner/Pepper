# Drift Firewall — Spec

**Status:** spec, not built. Build alongside the overnight batch — it's the quality gate that makes unattended production safe.

## What it is
A gate between still generation and clip animation: no still containing Pepper gets animated
(or packed) until it passes a character-consistency check against the model sheet.
Verdicts are logged, and the log becomes the evidence base for prompt and vendor decisions.

## The check (per still)
Against `bible/reference/media-generation-pepper-model-sheet-0-*.webp` (the chaining authority):

| Mark | Check |
|------|-------|
| Torn left ear, V-shaped notch | visible notch on the correct ear in any shot where the ear is visible |
| Crooked white nose stripe veering left | stripe present, veers left, in any front/three-quarter face shot |
| Oversized green eyes | green, oversized relative to head, in any face shot |
| White socks, front paws only | white on front paws, grey on rear, in any full-body shot |
| Style match | fur rendering, palette (lantern amber vs blue-green shadow), lighting and mood match `bible/style-lock.md` authority — not photorealistic, not Pixar-cartoon |

**Wide shots** (Pepper small in frame): marks not individually verifiable — pass with note `wide-shot`.
**Pepper absent** (e.g. Marlow-only, lift-only): pass with note `no-pepper`.

## Verdicts
- **PASS** — animate it.
- **RETRY** — regenerate with the same prompt once; if it fails twice, flag for human review.
- **HUMAN** — ambiguous (unusual angle, heavy shadow). Zohn eyeballs it. Never auto-pass a HUMAN.

## The drift log
`tools/drift-log.csv`, one row per still:
```
date,episode,shot,prompt_hash,model,vendor,ear,stripe,eyes,socks,verdict,notes
```
- `prompt_hash`: short hash of the generation prompt, so identical prompts are comparable.
- This log feeds two other systems: the prompt-winners log (which prompts reproduce Pepper best)
  and the vendor scoreboard (which models keep her marks).

## Implementation
1. **Manual gate first** (`tools/drift-check.md`): the checklist above as a markdown form. Used for ep001–ep004 while volume is low.
2. **Overnight-batch gate**: the batch script runs the checklist as a blocking step — stills without a PASS verdict never reach animation. Verdicts for the automated pass start as HUMAN until we have evidence the model judges reliably; the human clears the queue each morning (2-minute task).
3. **Later:** experiment with having the image model itself do the first-pass comparison (still vs. model sheet side by side, verdict + reason). Promote to auto-PASS only after 20 consecutive agreements with human verdicts.

## Rules
- The model sheet is the authority. The marks-detail sheet is the tiebreaker.
- A drifted still that airs is a continuity break — when in doubt, HUMAN, never ship it.
- Log every verdict, including passes. The log's value is in the pass-rate statistics.

## Acceptance
- Zero unaired-but-drifted stills reach the pack stage during the ep002–ep004 production run.
- The log has ≥15 rows after one week of production, enough to rank prompts.
