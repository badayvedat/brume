#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Récupère libghostty-spm à une version figée dans Vendor/ et y applique Patches/.
# Pour monter de version : changer TAG et COMMIT, relancer.

TAG="1.6.20261003"
COMMIT="54f38c0bcde7900bbf69144e084ab0418f640bbc"
DEST="Vendor/libghostty-spm"

STAMP="$COMMIT $(cat Patches/libghostty-spm-*.patch | shasum | cut -d' ' -f1)"
if [ -f "$DEST/.brume-stamp" ] && [ "$(cat "$DEST/.brume-stamp")" = "$STAMP" ]; then
    exit 0
fi

rm -rf "$DEST"
git -c advice.detachedHead=false clone -q --depth 1 --branch "$TAG" https://github.com/Lakr233/libghostty-spm.git "$DEST"
# Un tag peut être déplacé après coup : on n'accepte que le commit attendu.
if [ "$(git -C "$DEST" rev-parse HEAD)" != "$COMMIT" ]; then
    echo "Le tag $TAG ne pointe plus sur $COMMIT, arrêt." >&2
    rm -rf "$DEST"
    exit 1
fi
for patch in Patches/libghostty-spm-*.patch; do
    git -C "$DEST" apply "$PWD/$patch"
done
echo "$STAMP" > "$DEST/.brume-stamp"
echo "libghostty-spm $TAG prêt."
