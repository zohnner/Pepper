# Debt Counter Burn-In — Spec

**Status:** spec, not built. Build after ep001 posts and the pipeline is proven.

## What it is
A small HUD-style debt counter burned into every episode's video — e.g. `◈ 47` top-left —
that ticks to the new value at the debt-change moment. It turns each episode into a
visible progress update and makes rug-pull episodes (debt going UP) land harder.

## Design
- **Position:** top-left, below the platform UI safe zone (~120px from top, ~60px from left at 1080×1920).
- **Style:** amber `#E8A33D` on near-black `#0B0E14`, monospace-ish bold. Small — readable, not dominant.
- **Behavior:**
  - Appears at the episode's first debt mention (usually the hook), stays for the whole episode.
  - At the debt-change beat (the lift shot), it ticks from old → new over ~1s with a soft click sound.
  - If debt goes UP, the tick is red for 1s. (The cruelty is the point.)
- **Sound:** a single soft mechanical click per tick. Sourced royalty-free, stored in `assets/sfx/`.

## Data contract
Each episode pack gets a `debt.json`:
```json
{ "start": 47, "end": 46, "tick_at": "lift" }
```
- `tick_at` is the shot whose start triggers the tick (`"lift"` = final shot, the default).
- Written by whoever writes the script (G-Unit), validated by the continuity checker.

## Implementation
- Extend `tools/assemble-rough-cut.sh` (or a new `tools/burn-debt-counter.sh` it calls):
  1. Read `debt.json` from the pack.
  2. ffmpeg `drawtext` for the counter: `◈ {start}` from t=0, then `◈ {end}` from the lift shot's start time.
  3. For the tick animation, render 3 intermediate frames (start → mid → end) — simple, no fancy easing needed at this size.
  4. Mix the click SFX at the tick point, ducked under voiceover.
- Font: ship a free monospace (e.g. JetBrains Mono) in `tools/fonts/` so renders are reproducible.

## Acceptance
- Counter legible at 1080×1920 on a phone screen, clear of TikTok/Reels/Shorts UI chrome.
- Tick lands within ±0.3s of the lift shot's first frame.
- Works with debt going down, staying flat, or going up.

## Out of scope (for now)
- Animated progress-bar variants — test the numeric counter first, let retention data decide.
- Per-platform repositioning — one position that clears all three platforms' UI.
