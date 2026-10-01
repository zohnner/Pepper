# Script Template

## epNNN — Title

**Continuity check:** read `bible/continuity.md` first. This episode must follow from the last log entry.

### Hook (first line, 0-3s)
One flat, intriguing sentence. No setup, no greeting.
The hook gets its OWN visual (shot 0) — never let hook audio play over shot 1, or the whole
episode's narration lands one clip late (learned on ep001, 2026-10-01).

### Scenes

**Shot 1 — [visual description for prompt]**
Voiceover: ...

**Shot 2 — [visual description for prompt]**
Voiceover: ...

**Shot 3 — [visual description for prompt]**
Voiceover: ...

(3-5 shots per episode. Each shot = one still + one animated clip.)

### Complication
What goes wrong, stated in one line.

### Resolution + new debt
What Pepper wins, and what Marlow takes.

### The lift (final 3s, no dialogue)
One crank. Light from above a fraction closer. Cut.

### Word count
Target 60-90 words of voiceover total.

### Generation rules (learned from production)
- **Style is LOCKED** — see `bible/style-lock.md`. Use the style block verbatim in every still prompt,
  and chain BOTH the model sheet and `episodes/ep001/style-test/style-c-stylized.webp` on every generation.
- **Ear side:** the generator mirrors the torn ear unless the IMAGE side is spelled out.
  Always write "torn ear with V-shaped notch on the RIGHT SIDE OF THE IMAGE (her left ear)"
  in the Pepper block — never rely on "her left ear" alone.
- Vertical 9:16 only. Verify 1152×2048 (stills) before animating anything.
