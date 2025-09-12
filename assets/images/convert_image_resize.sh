#!/usr/bin/env bash
set -euo pipefail

in="${1:-}"                          # входной PNG или базовое имя без .png
outdir="${2:-windows/runner/resources/icons}"
sizes="${3:-180,120,87,60}"

[[ -z "$in" ]] && { echo "Usage: $0 <input(.png)> [outdir] [sizes_csv]"; exit 1; }
[[ "${in,,}" != *.png ]] && in="${in}.png"

cmd="$(command -v magick || command -v convert)"
mkdir -p "$outdir"

IFS=',' read -r -a ARR <<< "$sizes"
for s in "${ARR[@]}"; do
  "$cmd" "$in" -background none -gravity center \
    -resize "${s}x${s}^" -extent "${s}x${s}" \
    "PNG32:${outdir}/app_icon_${s}.png"
  echo "→ ${outdir}/app_icon_${s}.png"
done
