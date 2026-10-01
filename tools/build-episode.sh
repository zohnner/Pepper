#!/bin/bash
# build-episode.sh — one-command episode pack builder.
#
#   tools/build-episode.sh ep002 [--push] [--skip-voice] [--skip-caps]
#
# Pipeline (all derived from episodes/<ep>/beats.yaml, the single source of truth):
#   1. preflight   — beats.yaml valid; pack/<shot>.mp4 exists for every beat
#                    plus the silent end-card clip; debt.json continuity check
#   2. voiceover   — beats -> voiceover.txt -> tts speak (locked voice) -> pack/voiceover.mp3
#   3. captions    — faster-whisper word alignment -> pack/captions.srt
#   4. drift sheet — pack/drift-review.jpg + drift-log.csv rows (human 2-min gate)
#   5. edit notes  — pack/edit-notes.md stub (beat table, tick, review checklist)
#   6. assemble    — pack/rough-cut.mp4 (beat-trimmed, captions + debt HUD burned in)
#   7. verify      — duration sanity check
#   8. push        — ONLY with --push: push-pack.py to zohnner/Pepper
#
# What stays manual (agent-driven, see tools/episode-runbook.md):
#   - still generation + clip animation (media.* tools need an agent)
#   - the drift eyeball (2 minutes on drift-review.jpg, verdicts into drift-log.csv)
#   - Zohn's CapCut polish + native posting
set -e
cd "$(dirname "$0")/.."

EP="${1:?usage: build-episode.sh <ep> [--push] [--skip-voice] [--skip-caps]}"
PUSH=false; SKIP_VOICE=false; SKIP_CAPS=false
for a in "$@"; do
  case "$a" in
    --push) PUSH=true;; --skip-voice) SKIP_VOICE=true;; --skip-caps) SKIP_CAPS=true;;
  esac
done

BEATS="episodes/$EP/beats.yaml"
PACK="episodes/$EP/pack"
VPY="/home/hatch/workspace/.venvs/pepper/bin/python"
[ -x "$VPY" ] || VPY="python3"
mkdir -p "$PACK"

echo "=== 1. preflight ==="
[ -f "$BEATS" ] || { echo "MISSING $BEATS — write it first (see templates/beats-template.yaml)"; exit 1; }
SHOTS=$($VPY tools/make-captions.py shots "$BEATS")
echo "beats: $SHOTS"
MISSING=0
for s in $SHOTS; do
  [ -f "$PACK/$s.mp4" ] || { echo "MISSING clip $PACK/$s.mp4"; MISSING=1; }
done
# end-card: one clip past the highest-numbered beat, silent crank shot
LAST_BEAT=$(echo "$SHOTS" | tr ' ' '\n' | sort | tail -1)
END_CARD=$(printf "%02d" $((10#$LAST_BEAT + 1)))
[ -f "$PACK/$END_CARD.mp4" ] || { echo "MISSING end-card clip $PACK/$END_CARD.mp4 (silent crank)"; MISSING=1; }
[ "$MISSING" = "1" ] && { echo "Generate the missing clips first (tools/episode-runbook.md)."; exit 1; }

# debt continuity: this episode's start must equal the previous episode's end
if [ -f "$PACK/debt.json" ]; then
  N=$(echo "$EP" | sed 's/ep//' | awk '{print $1+0}')
  PREV=$(printf "ep%03d" $((N-1)))
  PREV_END=47
  [ -f "episodes/$PREV/pack/debt.json" ] && PREV_END=$(python3 -c "import json;print(json.load(open('episodes/$PREV/pack/debt.json'))['end'])")
  START=$(python3 -c "import json;print(json.load(open('$PACK/debt.json'))['start'])")
  if [ "$START" != "$PREV_END" ]; then
    echo "WARNING: debt.json start ($START) != $PREV end ($PREV_END) — fix before posting"
  else
    echo "debt continuity ok: $PREV_END -> ... "
  fi
fi

echo "=== 2. voiceover ==="
if [ "$SKIP_VOICE" = true ] && [ -f "$PACK/voiceover.mp3" ]; then
  echo "skipped (existing pack/voiceover.mp3)"
else
  VOICE=$($VPY tools/make-captions.py voice "$BEATS")
  echo "voice: $VOICE"
  $VPY tools/make-captions.py voiceover-txt "$BEATS" "$PACK/voiceover-src.txt"
  cp "$PACK/voiceover-src.txt" "episodes/$EP/voiceover.txt"
  /opt/hatch/bin/tts speak --voice "$VOICE" --output "$PACK/voiceover.mp3" \
    --text-stdin < "$PACK/voiceover-src.txt"
fi

echo "=== 3. captions ==="
if [ "$SKIP_CAPS" = true ] && [ -f "$PACK/captions.srt" ]; then
  echo "skipped (existing pack/captions.srt)"
else
  $VPY tools/make-captions.py captions "$BEATS" "$PACK/voiceover.mp3" "$PACK/captions.srt"
fi

echo "=== 4. drift review sheet ==="
$VPY tools/drift-contact-sheet.py "$EP"

echo "=== 5. edit notes ==="
python3 - "$BEATS" "$PACK" <<'PYEOF'
import re, sys, json, os
beats_path, pack = sys.argv[1], sys.argv[2]
text = open(beats_path).read()
shots = re.findall(r'shot:\s*"(\d+)"', text)
caps = re.findall(r'(\d+):(\d+):(\d+),(\d+)\s*-->\s*(\d+):(\d+):(\d+),(\d+)', open(f"{pack}/captions.srt").read())
def sec(h,m,s,ms): return int(h)*3600+int(m)*60+int(s)+int(ms)/1000.0
lines = [f"# Edit notes — {os.path.basename(os.path.dirname(pack))}", "",
         "| beat | shot | start | end |", "|------|------|-------|-----|"]
for i,(sh,(h1,mi1,s1,ms1,h2,mi2,s2,ms2)) in enumerate(zip(shots, caps)):
    lines.append(f"| {i+1} | {sh} | {sec(h1,mi1,s1,ms1):.1f}s | {sec(h2,mi2,s2,ms2):.1f}s |")
if os.path.exists(f"{pack}/debt.json"):
    d = json.load(open(f"{pack}/debt.json"))
    lines += ["", f"Debt HUD: {d['start']} -> {d['end']}, tick at shot {d.get('tick_at','lift')}."]
lines += ["", "## Review before CapCut",
          "- [ ] drift-review.jpg eyeballed; verdicts in tools/drift-log.csv",
          "- [ ] every caption matches its visual; no caption stranded on the wrong shot",
          "- [ ] debt counter (if any) ticks at the right moment",
          "- [ ] voiceover pacing feels right; no rushed beats"]
open(f"{pack}/edit-notes.md","w").write("\n".join(lines)+"\n")
print(f"wrote {pack}/edit-notes.md")
PYEOF

echo "=== 6. assemble ==="
tools/assemble-rough-cut.sh "$PACK"

echo "=== 7. verify ==="
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$PACK/rough-cut.mp4")
printf "rough cut: %.1fs\n" "$DUR"
python3 -c "import sys; d=float(sys.argv[1]); sys.exit(0 if 25 <= d <= 35 else 1)" "$DUR" \
  || echo "WARNING: duration outside 25-35s — check the beat trims"

if [ "$PUSH" = true ]; then
  echo "=== 8. push ==="
  tools/push-pack.py "$EP" "$EP: automated pack build (voice + captions + rough cut)"
else
  echo "(push skipped — rerun with --push after the drift eyeball)"
fi
echo "DONE: $PACK/rough-cut.mp4"
