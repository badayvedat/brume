#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Fabrique .build/Brume.dmg : l'app en release, à glisser dans Applications sur le fond de Resources/dmg.
# Demande rsvg-convert (brew install librsvg) et pipx (brew install pipx), qui lance dmgbuild sans l'installer.

DMGBUILD_VERSION="1.6.7"
OUT=".build/Brume.dmg"

bash scripts/build-app.sh --no-install

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# Fond en @1x et @2x dans un même TIFF : le Finder prend la bonne taille selon l'écran.
rsvg-convert -w 660 -h 420 Resources/dmg/background.svg -o "$WORK/background.png"
rsvg-convert -w 1320 -h 840 Resources/dmg/background.svg -o "$WORK/background@2x.png"
tiffutil -cathidpicheck "$WORK/background.png" "$WORK/background@2x.png" -out "$WORK/background.tiff" 2>/dev/null

rm -f "$OUT"
pipx run --spec "dmgbuild==$DMGBUILD_VERSION" dmgbuild \
    -s scripts/dmg-settings.py \
    -D app=.build/app/Brume.app \
    -D icon=Resources/AppIcon.icns \
    -D background="$WORK/background.tiff" \
    "Brume" "$OUT"
echo "$OUT"
