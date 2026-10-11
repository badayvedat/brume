#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Prépare une version publiable : numéros, tests, DMG signé pour Sparkle, entrée de l'appcast.
# S'arrête avant toute action publique et affiche les commandes à lancer ensuite.
#
# Usage : bash scripts/release.sh 0.2.0

VERSION="${1:-}"
TAG="v$VERSION"
DMG=".build/Brume.dmg"
NOTES=".build/release-notes.md"
REPO="jeremy-prt/brume"
MIN_SYSTEM="26.0"

fail() {
    echo "$1" >&2
    exit 1
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Usage : bash scripts/release.sh <version>, par exemple 0.2.0"

[ -f CHANGELOG.md ] || fail "CHANGELOG.md absent."
grep -Eq "^## ${VERSION//./\\.}( |$)" CHANGELOG.md \
    || fail "CHANGELOG.md n'a pas de section « ## $VERSION » : l'ajouter avant de publier."
grep -Eq "^## ${VERSION//./\\.} - [0-9]{4}-[0-9]{2}-[0-9]{2}$" CHANGELOG.md \
    || fail "La section « ## $VERSION » de CHANGELOG.md n'a pas de date : écrire « ## $VERSION - $(date +%F) »."

# Le corps de la section, sans son titre, jusqu'à la version suivante.
SECTION="$(awk -v v="$VERSION" '/^## / { if (inside) exit; inside = ($2 == v); next } inside' CHANGELOG.md)"
grep -Eq '^[-*] ' <<< "$SECTION" || fail "La section « ## $VERSION » de CHANGELOG.md ne liste aucun changement."

[ -z "$(git status --porcelain)" ] || fail "L'arbre git n'est pas propre : commiter ou mettre de côté avant de publier."
[ "$(git branch --show-current)" = "main" ] || fail "À lancer depuis main : l'app lit l'appcast sur cette branche."
git rev-parse -q --verify "refs/tags/$TAG" > /dev/null && fail "Le tag $TAG existe déjà."
[ -z "$(git ls-remote --tags origin "refs/tags/$TAG" 2> /dev/null)" ] || fail "Le tag $TAG existe déjà sur GitHub."

command -v rsvg-convert > /dev/null || fail "rsvg-convert absent : brew install librsvg"
command -v pipx > /dev/null || fail "pipx absent : brew install pipx"

# Un échec plus loin remet les deux fichiers touchés dans l'état du dernier commit.
DONE=0
ITEM="$(mktemp)"
restore() {
    rm -f "$ITEM"
    [ "$DONE" = 1 ] && return
    git checkout -q -- scripts/build-app.sh appcast.xml
    echo "Échec : scripts/build-app.sh et appcast.xml remis comme avant." >&2
}
trap restore EXIT

BUILD=$(( $(sed -n 's/^BUILD_NUMBER="\([0-9]*\)"$/\1/p' scripts/build-app.sh) + 1 ))
sed -i '' -e "s/^VERSION=\".*\"$/VERSION=\"$VERSION\"/" -e "s/^BUILD_NUMBER=\".*\"$/BUILD_NUMBER=\"$BUILD\"/" scripts/build-app.sh
echo "Brume $VERSION, build $BUILD."

bash scripts/run-tests.sh
bash scripts/make-dmg.sh

# Lit la clé privée EdDSA dans le trousseau : macOS peut demander d'y autoriser l'accès.
echo "Signature du DMG pour Sparkle..."
SIGNATURE="$(Vendor/sparkle/bin/sign_update -p "$DMG")"
LENGTH="$(stat -f%z "$DMG")"
SHA256="$(shasum -a 256 "$DMG" | cut -d' ' -f1)"

awk 'NF { started = 1 } started' <<< "$SECTION" > "$NOTES"

# Les notes en HTML pour la fenêtre de Sparkle : un titre par rubrique, puis sa liste.
HTML="$(awk '
    function esc(s) {
        gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s)
        while (match(s, /`[^`]+`/)) s = substr(s, 1, RSTART - 1) "<code>" substr(s, RSTART + 1, RLENGTH - 2) "</code>" substr(s, RSTART + RLENGTH)
        return s
    }
    function flush() { if (item != "") print "                    <li>" esc(item) "</li>"; item = "" }
    function close_list() { flush(); if (open) print "                </ul>"; open = 0 }
    /^### / { close_list(); print "                <h2>" esc(substr($0, 5)) "</h2>"; next }
    /^[-*] / { flush(); if (!open) { print "                <ul>"; open = 1 } item = substr($0, 3); next }
    /^[ \t]+[^ \t]/ && item != "" { sub(/^[ \t]+/, ""); item = item " " $0; next }
    END { close_list() }
' "$NOTES")"

cat > "$ITEM" << XML
        <item>
            <title>Version $VERSION</title>
            <pubDate>$(LC_ALL=C date -R)</pubDate>
            <sparkle:version>$BUILD</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>$MIN_SYSTEM</sparkle:minimumSystemVersion>
            <description><![CDATA[
$HTML
            ]]></description>
            <enclosure
                url="https://github.com/$REPO/releases/download/$TAG/Brume.dmg"
                sparkle:edSignature="$SIGNATURE"
                length="$LENGTH"
                type="application/octet-stream"
            />
        </item>
XML

# En tête de la liste : avant la première version, ou avant la fin du flux s'il n'y en a pas.
awk -v item="$ITEM" '
    !done && (/<item>/ || /<\/channel>/) { while ((getline line < item) > 0) print line; done = 1 }
    { print }
' appcast.xml > appcast.xml.new
mv appcast.xml.new appcast.xml
xmllint --noout appcast.xml

DONE=1
cat << EOF

Brume $VERSION est prête : $DMG (build $BUILD), entrée ajoutée en tête de appcast.xml.

1. Essayer le DMG : l'ouvrir, glisser Brume dans Applications, le lancer.

2. Publier, dans cet ordre : l'appcast ne passe en ligne qu'avec le push de main, une fois
   le DMG en ligne.

   git add scripts/build-app.sh appcast.xml
   git commit -m "config: version $VERSION"
   git tag $TAG
   git push origin $TAG
   gh release create $TAG $DMG --title "Brume $VERSION" --notes-file $NOTES
   git push origin main
   bash scripts/update-tap.sh $VERSION $SHA256
EOF
