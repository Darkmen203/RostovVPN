#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash assets/images/png2tvos_one.sh <front.png> <bgcolor> [outdir] [pad_percent_per_side]
# Examples:
#   bash assets/images/png2tvos_one.sh ./logo.png "#0E66FF"
#   bash assets/images/png2tvos_one.sh ./logo.png "#0E66FF" ./assets/tvos-icons 10

front_src="${1:-}"; bg="${2:-}"; outdir="${3:-.}"; pad_pct="${4:-12}"
[ -n "${front_src}" ] || { echo "Need <front.png>"; exit 1; }
[ -n "${bg}" ]       || { echo "Need <bgcolor> (e.g. #0E66FF)"; exit 1; }
[ -f "${front_src}" ]|| { echo "File not found: ${front_src}"; exit 1; }

# Ограничим разумный диапазон отступа: 0..45% на сторону
pad_pct_num=$(printf "%d" "${pad_pct}" 2>/dev/null || echo 12)
if [ "${pad_pct_num}" -lt 0 ];  then pad_pct_num=0;  fi
if [ "${pad_pct_num}" -gt 45 ]; then pad_pct_num=45; fi

mkdir -p "${outdir}"

cmd="$(command -v magick || command -v convert || true)"
[ -n "$cmd" ] || { echo "ImageMagick not found (need 'magick' or 'convert')"; exit 1; }

# Набор размеров tvOS 5:3
sizes=("400x240:400" "800x480:400@2x" "1280x768:1280x768", "256x256:LaunchImage", "512x512:LaunchImage@2x", "768x768:LaunchImage@3x")

for item in "${sizes[@]}"; do
  IFS=: read -r size suffix <<< "$item"
  W="${size%x*}"; H="${size#*x}"

  # Внутреннее «окно» под логотип: уменьшаем на 2*pad по каждой оси
  innerW=$(awk -v w="$W" -v p="$pad_pct_num" 'BEGIN{printf("%d", w*(1-2*p/100.0))}')
  innerH=$(awk -v h="$H" -v p="$pad_pct_num" 'BEGIN{printf("%d", h*(1-2*p/100.0))}')
  if [ "$innerW" -lt 1 ]; then innerW=1; fi
  if [ "$innerH" -lt 1 ]; then innerH=1; fi

  # FRONT: вписываем (contain), центрируем, докладываем прозрачный холст
  "$cmd" "$front_src" -alpha on -background none -gravity center \
    -resize "${innerW}x${innerH}" -extent "${W}x${H}" -strip \
    "${outdir}/app-icon-front-${suffix}.png"

  # MIDDLE: однотонный фон (можно заменить на свой PNG/градиент)
  "$cmd" -size "${W}x${H}" "xc:${bg}" -alpha on -strip \
    "${outdir}/app-icon-middle-${suffix}.png"

  echo "✓ front ${W}x${H} -> ${outdir}/app-icon-front-${suffix}.png (pad ${pad_pct_num}%/side)"
  echo "✓ middle ${W}x${H} -> ${outdir}/app-icon-middle-${suffix}.png"
done

echo "Done."
