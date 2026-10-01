#!/bin/bash
# new-episode.sh — scaffold the next episode folder from templates.
# Usage: ./new-episode.sh
set -e
cd "$(dirname "$0")/.."
LAST=$(ls episodes | grep -E '^ep[0-9]+$' | sort | tail -1)
NUM=$(echo "$LAST" | sed 's/ep//' | awk '{print $1+1}')
NEXT=$(printf "ep%03d" "$NUM")
mkdir -p "episodes/$NEXT/assets"
for t in script prompt meta; do
  cp "templates/${t}-template.md" "episodes/$NEXT/${t}.md"
done
touch "episodes/$NEXT/voiceover.txt"
echo "Scaffolded episodes/$NEXT — update episodes/TRACKER.md with a new row."
