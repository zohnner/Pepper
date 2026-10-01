#!/bin/bash
# assemble-rough-cut.sh — build a draft episode MP4 from a pack.
# Usage: ./assemble-rough-cut.sh ep001
# Input:  episodes/<ep>/pack/{00.mp4..NN.mp4, voiceover.mp3, captions.srt}
# Output: episodes/<ep>/pack/rough-cut.mp4
#
# Each numbered clip is trimmed to its narrative beat, derived from
# captions.srt (clip i <-> caption i+1, so the hook caption's clip is the
# hook visual, etc.). Clips past the last caption get a TAIL_DUR end-card
# hold (default 3.5s). Burned-in captions keep their SRT timings, which now
# match the visual cuts by construction.
#
# The rough cut is a DRAFT. Zohn's CapCut pass adds the music bed, cover,
# and final polish.
set -euo pipefail

ARG="${1:?usage: assemble-rough-cut.sh <epNNN> | <pack-dir>}"
TAIL_DUR="${TAIL_DUR:-3.5}"   # end-card hold for clips past the last caption
if [[ "$ARG" == *"/"* ]]; then PACK="$ARG"; else PACK="$(dirname "$0")/../episodes/$ARG/pack"; fi
OUT="$PACK/rough-cut.mp4"

cd "$PACK"
CLIPS=( $(ls [0-9][0-9].mp4 2>/dev/null | sort) )
if [ ${#CLIPS[@]} -eq 0 ]; then echo "no numbered clips in $PACK"; exit 1; fi
[ -f voiceover.mp3 ] || { echo "voiceover.mp3 missing in $PACK"; exit 1; }
[ -f captions.srt ] || { echo "captions.srt missing in $PACK"; exit 1; }

# Convert SRT -> ASS with an explicit 1080x1920 script resolution.
# (Burning the SRT directly makes libass fall back to a 384x288 script
# resolution, which inflates FontSize/MarginV ~6.7x: giant captions pinned
# to the top of the frame.)
ASS="$PACK/captions.ass"
python3 - "$PACK/captions.srt" "$ASS" <<'PYEOF'
import re, sys
srt_path, ass_path = sys.argv[1], sys.argv[2]
text = open(srt_path).read().strip()
blocks = re.split(r"\n\s*\n", text)
def ts(t):
    h, m, rest = t.split(":"); s, ms = rest.split(",")
    return f"{int(h)}:{m}:{s}.{ms[:2]}"
events = []
for b in blocks:
    lines = b.strip().split("\n")
    if len(lines) < 3: continue
    m = re.match(r"(\d+:\d+:\d+,\d+)\s*-->\s*(\d+:\d+:\d+,\d+)", lines[1])
    if not m: continue
    dlg = "\\N".join(lines[2:]).replace("{", "\\{").replace("}", "\\}")
    events.append(f"Dialogue: 0,{ts(m.group(1))},{ts(m.group(2))},Cap,,0,0,0,,{dlg}")
ass = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0
ScaledBorderAndShadow: yes
YCbCr Matrix: TV.709

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Cap,DejaVu Serif,64,&H00FFFFFF,&H000019FF,&H80000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,1,2,60,60,260,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
""" + "\n".join(events) + "\n"
open(ass_path, "w").write(ass)
print(f"wrote {ass_path} ({len(events)} events)", file=sys.stderr)
PYEOF

# Derive one duration per clip from the caption beats.
DURS="$(python3 - "$PACK/captions.srt" "$TAIL_DUR" "${#CLIPS[@]}" <<'PYEOF'
import re, sys
srt_path, tail, nclips = sys.argv[1], float(sys.argv[2]), int(sys.argv[3])
text = open(srt_path).read()
blocks = re.findall(r"(\d+):(\d+):(\d+),(\d+)\s*-->\s*(\d+):(\d+):(\d+),(\d+)", text)
def sec(h, m, s, ms): return int(h)*3600 + int(m)*60 + int(s) + int(ms)/1000.0
caps = [(sec(*b[0:4]), sec(*b[4:8])) for b in blocks]
durs, t = [], 0.0
for i in range(nclips):
    if i < len(caps):
        d = caps[i][1] - t          # absorb any gap between captions into the clip
        if d < 0.5:
            print(f"warning: caption {i+1} ends before clip {i} starts; clamping", file=sys.stderr)
            d = 0.5
    else:
        d = tail
    durs.append(d); t += d
if nclips < len(caps):
    # More beats than clips: stretch the last clip to cover the final caption.
    start_last = t - durs[-1]
    durs[-1] = caps[-1][1] - start_last
    print(f"warning: {len(caps)} captions but only {nclips} clips; last clip stretched to {durs[-1]:.2f}s",
          file=sys.stderr)
print(" ".join(f"{d:.3f}" for d in durs))
print(f"total {t:.2f}s -> {' '.join(f'{d:.1f}' for d in durs)}", file=sys.stderr)
PYEOF
)"
read -ra DUR_ARR <<< "$DURS"

# Build concat input list, trimming each clip to its beat and normalizing
# every clip to 1080x1920@30fps
INPUTS=(); FILTER=""; N=0
for c in "${CLIPS[@]}"; do
  INPUTS+=(-i "$c")
  DUR="${DUR_ARR[$N]}"
  FILTER+="[${N}:v]trim=0:${DUR},setpts=PTS-STARTPTS,scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30,format=yuv420p[v${N}];"
  N=$((N+1))
done
INPUTS+=(-i voiceover.mp3)
for i in $(seq 0 $((N-1))); do FILTER+="[v${i}]"; done
FILTER+="concat=n=${N}:v=1:a=0[vout]"
# Voiceover padded to picture length
FILTER+=";[${N}:a]apad,atrim=0:9999[aout]"

SUB=""
# Burn the generated ASS (explicit 1080x1920 script resolution, so the
# style renders at true pixel size). The .ass is regenerated from the
# .srt on every run, so the SRT stays the source of truth.
ESCAPED="$(echo "$ASS" | sed "s/'/\\\\'/g")"
SUB=",subtitles=filename='${ESCAPED}'"

if [ -n "$SUB" ]; then
  VCHAIN=";[vout]${SUB#,},format=yuv420p[vfinal]"
else
  VCHAIN=";[vout]format=yuv420p[vfinal]"
fi

ffmpeg -y "${INPUTS[@]}" \
  -filter_complex "${FILTER}${VCHAIN}" \
  -map "[vfinal]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 160k \
  -movflags +faststart -shortest \
  "$OUT"

echo "wrote $OUT"
