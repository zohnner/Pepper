#!/bin/bash
# assemble-rough-cut.sh — build a draft episode MP4 from a pack.
# Usage: ./assemble-rough-cut.sh ep001
# Input:  episodes/<ep>/pack/{01.mp4..NN.mp4, voiceover.mp3, captions.srt}
# Output: episodes/<ep>/pack/rough-cut.mp4
#
# The rough cut is a DRAFT: concatenated clips + voiceover + burned-in
# captions. Zohn's CapCut pass adds the music bed, cover, and final polish.
set -euo pipefail

ARG="${1:?usage: assemble-rough-cut.sh <epNNN> | <pack-dir>}"
if [[ "$ARG" == *"/"* ]]; then PACK="$ARG"; else PACK="$(dirname "$0")/../episodes/$ARG/pack"; fi
OUT="$PACK/rough-cut.mp4"

cd "$PACK"
CLIPS=( $(ls [0-9][0-9].mp4 2>/dev/null | sort) )
if [ ${#CLIPS[@]} -eq 0 ]; then echo "no numbered clips in $PACK"; exit 1; fi
[ -f voiceover.mp3 ] || { echo "voiceover.mp3 missing in $PACK"; exit 1; }

# Build concat input list, normalizing every clip to 1080x1920@30fps
INPUTS=(); FILTER=""; N=0
for c in "${CLIPS[@]}"; do
  INPUTS+=(-i "$c")
  FILTER+="[${N}:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30,format=yuv420p[v${N}];"
  N=$((N+1))
done
INPUTS+=(-i voiceover.mp3)
for i in $(seq 0 $((N-1))); do FILTER+="[v${i}]"; done
FILTER+="concat=n=${N}:v=1:a=0[vout]"
# Voiceover padded/trimmed to picture length
FILTER+=";[${N}:a]apad,atrim=0:9999[aout]"

FONT="/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SUB=""
if [ -f captions.srt ]; then
  # Escape for the subtitles filter (single quotes inside the arg)
  ESCAPED="$(echo "$PACK/captions.srt" | sed "s/'/\\\\'/g")"
  SUB=",subtitles=filename='${ESCAPED}':force_style='FontName=DejaVu Serif,FontSize=64,PrimaryColour=&H00FFFFFF,OutlineColour=&H80000000,BorderStyle=1,Outline=3,Shadow=1,Alignment=2,MarginV=260'"
fi

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
