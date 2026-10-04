#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Régénère Resources/AppIcon.icns depuis Resources/AppIcon.svg, toutes les tailles en @1x et @2x.
# Demande rsvg-convert (brew install librsvg) : le script de build, lui, copie l'icns sans le refaire.

ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    rsvg-convert -w "$size" -h "$size" Resources/AppIcon.svg -o "$ICONSET/icon_${size}x${size}.png"
    rsvg-convert -w $((size * 2)) -h $((size * 2)) Resources/AppIcon.svg -o "$ICONSET/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
rm -rf "$(dirname "$ICONSET")"
echo "Resources/AppIcon.icns"
