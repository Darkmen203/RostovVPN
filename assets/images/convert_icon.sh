#!/usr/bin/env bash
set -euo pipefail

src="${1:-}"
[ -z "$src" ] && { echo "Usage: $0 <input(.png)> [sizes_csv]"; exit 1; }

# если передали без .png — добавим
case "${src,,}" in
  *.png) : ;;
  *) src="${src}.png" ;;
esac

# размеры по умолчанию
sizes="${2:-256,128,64,48,32,16}"

# ImageMagick v7: magick, v6: convert
cmd="$(command -v magick || command -v convert || true)"
[ -n "$cmd" ] || { echo "ImageMagick не найден (magick/convert)"; exit 1; }

# проверим, что вход существует
[ -f "$src" ] || { echo "Файл не найден: $src"; exit 1; }

# базовое имя для .ico
base="${src%.png}"
ico="${base}.ico"

# делаем ICO (центрируем и приводим к квадрату, если нужно)
"$cmd" "$src" \
  -alpha on -background none -gravity center \
  -define "icon:auto-resize=$sizes" \
  "$ico"

echo "✓ Готово: $ico"
