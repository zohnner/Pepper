# Style Lock — Pepper series

**Status: LOCKED 2026-10-01 by Zohn.** Chosen from a 3-way style test (variants A "Noir Cinematic"
and B "Storybook Cartoon" were blocked by the image pipeline's filter; C was approved as-is).

## Authority images
Chain BOTH on every still generation, no exceptions:
1. `bible/reference/media-generation-pepper-model-sheet-0-b738aac2-6ba8-437a-abb0-a4d5fd7aa41a.webp` — character marks
2. `episodes/ep001/style-test/style-c-stylized.webp` — the locked look

## The style block (use verbatim in every still prompt)
> Stylized 3D storybook noir. Painterly-detailed fur with visible stylized texture, slightly
> exaggerated proportions, expressive but not cartoonish. Bold lantern-amber key light against
> deep blue-green shadow, strong contrast, wet reflective cobblestones, volumetric lantern glow,
> moody cinematic composition, richly detailed environment.

## Palette and light
- Key: lantern amber (warm, glowing, volumetric)
- Fill/ambient: deep blue-green shadow
- Surfaces: wet brick, reflective cobblestones, drips and puddles encouraged
- Contrast: strong. Mood: moody cinematic, never flat daylight, never high-key cheerful.

## Hard no's (observed drift, do not repeat)
- Photorealistic individual-strand fur / naturalistic proportions (old shot 1)
- Pixar-smooth cartoon look, oversized cartoon eyes, rounded toy-like shapes (old shot 2)
- Steampunk clutter drift — busy gears/props crowding the frame (old shot 3 leaned this way)

## Generation rules
- Vertical 9:16 only, 1152×2048. Verify dimensions before animating.
- Ear-side phrasing always: "torn ear with V-shaped notch on the RIGHT SIDE OF THE IMAGE (her left ear)".
- Pepper's four marks checked per the drift firewall; style match checked against authority image #2.
- If a still's style drifts from the authority, regenerate — never "fix it in post".
