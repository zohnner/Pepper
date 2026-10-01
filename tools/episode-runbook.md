# Episode Runbook — the agent-driven half of the pipeline

`tools/build-episode.sh` handles voice, captions, assembly, and push. This
runbook covers what it can't: stills and animation. Those go through the
`media.*` tools, which need an agent — so the per-episode flow is:

> Zohn (or a scheduled job) says "build epNNN" → agent runs this runbook →
> `tools/build-episode.sh epNNN` → drift eyeball → `--push`

## 0. Read first

- `episodes/<ep>/script.md` — the episode's beats and continuity
- `episodes/<ep>/prompts.md` — per-shot visual prompts + the style block
- `episodes/<ep>/beats.yaml` — caption text per shot (must match the script)
- `bible/continuity.md` — the log is law; the new episode must start where
  the last one left Pepper, and `pack/debt.json` must chain the debt

## 1. Stills — one `media.generate_image` call per shot

For every shot in prompts.md (plus the hook shot "00" and the silent
end-card crank shot):

- `output_dir`: the episode's `assets/` directory (absolute path, no `~`)
- `name`: `ep<NNN>-shot<k>-stylec` (k = 00, 01, 02, …)
- prompt entries, in order:
  1. `{kind: image, value: <model sheet path>}` — the chaining authority
  2. `{kind: image, value: <style-c authority path>}` —
     `episodes/ep001/style-test/style-c-stylized.webp`
  3. `{kind: text, value: <the shot prompt>}` — prepend the style block
     from prompts.md, and append the required ear wording verbatim for any
     shot where Pepper's ears are visible:

     > torn ear with V-shaped notch on the RIGHT SIDE OF THE IMAGE (her left ear)

  4. Exclude block (append to the text): no photorealistic
     individual-strand fur, no Pixar-smooth toy-like cartoon look, no
     cluttered steampunk drift.

- 1080×1920 vertical. If a call returns landscape, regenerate — do not
  crop-stretch a wrong-aspect still into the pack.

Max 4 `media.generate_image` calls per response; an episode's 6 shots take
two rounds. Check each still before moving on (open the returned file).

## 2. Drift gate — before any animation

1. Run `tools/drift-contact-sheet.py <ep>` (build-episode.sh does this too).
2. Open `pack/drift-review.jpg`. For every still containing Pepper, check
   against the model sheet row at the top:
   - torn left ear, V-shaped notch, on the RIGHT SIDE OF THE IMAGE
   - crooked white nose stripe veering left
   - oversized green eyes
   - white socks on front paws only
   - style: storybook noir (lantern amber vs blue-green shadow) — not
     photoreal, not Pixar-smooth
3. Wide shots (Pepper tiny) and no-Pepper shots pass with a note.
4. Record verdicts in `tools/drift-log.csv` (PASS / RETRY / HUMAN).
   RETRY regenerates once with the same prompt; a second failure → HUMAN.
   Never ship a HUMAN still without Zohn's eyeball.
5. Only PASS stills get animated.

## 3. Animation — one `media.generate_video` call per PASS still

- `prompt`: `[{kind: image, value: <still path>}, {kind: text, value:
  <animation direction>}]` — the animation direction comes from prompts.md
  ("slow push-in", "lateral drift", …). Keep motion slow; TikTok rewards
  readable motion, not swoops.
- `output_dir`: the episode's `assets/`; `name`: `ep<NNN>-shot<k>-anim`.
- Save the winner as `pack/<k>.mp4` — the two-digit shot number must match
  the beat's `shot:` in beats.yaml, because the assembler trims clip i to
  caption i+1. The end-card crank shot is the highest number, silent.

## 4. Hand off to the script

Run `tools/build-episode.sh <ep>` (no `--push` yet). It does voiceover,
word-accurate captions, the drift sheet, edit notes, and the rough cut.
Do the drift eyeball (step 2) if not done already, fix anything flagged,
re-run the script, then `tools/build-episode.sh <ep> --push`.

## 5. Close out

- Update `episodes/TRACKER.md` (stills/clips/voice/edit columns).
- Append the continuity entry to `bible/continuity.md`.
- Tell Zohn the pack is ready for his CapCut pass — never mark an episode
  "ready to post" before he approves the cut.
