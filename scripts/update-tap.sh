#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Met à jour Casks/brume.rb du dépôt jeremy-prt/homebrew-tap (version et empreinte du DMG) par l'API GitHub :
# pas de clone, le compte connecté à gh suffit. À lancer après la publication de la release.
#
# Usage : bash scripts/update-tap.sh 0.2.0 <sha256 affiché par scripts/release.sh>

VERSION="${1:-}"
SHA256="${2:-}"
TAP="jeremy-prt/homebrew-tap"
CASK="Casks/brume.rb"
URL="https://github.com/jeremy-prt/brume/releases/download/v$VERSION/Brume.dmg"

fail() {
    echo "$1" >&2
    exit 1
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Usage : bash scripts/update-tap.sh <version> <sha256>"
[[ "$SHA256" =~ ^[0-9a-f]{64}$ ]] || fail "Empreinte invalide : reprendre le sha256 affiché par scripts/release.sh."
command -v gh > /dev/null || fail "gh absent : brew install gh"

# Le cask ne doit pointer que vers un DMG en ligne et identique au DMG signé : sinon brew install échoue pour tous
echo "Vérification du DMG en ligne..."
ONLINE="$(curl -sfL "$URL" | shasum -a 256 | cut -d' ' -f1)" || fail "Le DMG de la v$VERSION n'est pas en ligne : publier la release d'abord."
[ "$ONLINE" = "$SHA256" ] || fail "Le DMG en ligne ($ONLINE) ne correspond pas à l'empreinte donnée."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# Sous Casks/ : brew style ne reconnaît un cask qu'à son chemin
mkdir "$WORK/Casks"

BLOB="$(gh api "repos/$TAP/contents/$CASK" --jq .sha)"
gh api "repos/$TAP/contents/$CASK" --jq .content | base64 --decode > "$WORK/current.rb"
sed -e "s/^  version \".*\"$/  version \"$VERSION\"/" -e "s/^  sha256 \".*\"$/  sha256 \"$SHA256\"/" "$WORK/current.rb" > "$WORK/Casks/brume.rb"

grep -q "^  version \"$VERSION\"$" "$WORK/Casks/brume.rb" && grep -q "^  sha256 \"$SHA256\"$" "$WORK/Casks/brume.rb" \
    || fail "Lignes version ou sha256 introuvables dans $CASK : le mettre à jour à la main."
if cmp -s "$WORK/current.rb" "$WORK/Casks/brume.rb"; then
    echo "Le cask est déjà en $VERSION."
    exit 0
fi
if command -v brew > /dev/null; then
    STYLE="$(brew style "$WORK/Casks/brume.rb" 2>&1)" || fail "brew style refuse le nouveau cask :
$STYLE"
fi

gh api -X PUT "repos/$TAP/contents/$CASK" \
    -f message="config: Brume $VERSION" \
    -f content="$(base64 < "$WORK/Casks/brume.rb")" \
    -f sha="$BLOB" \
    --jq .commit.html_url
echo "Homebrew propose Brume $VERSION : brew upgrade --cask brume"
