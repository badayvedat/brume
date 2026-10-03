#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Récupère les dépendances à des versions figées dans Vendor/ et applique Patches/.
# Pour monter de version : changer le tag et le commit, relancer.

# Un tag peut être déplacé après coup : on n'accepte que le commit attendu.
clone_pinned() {
    local url="$1" tag="$2" commit="$3" dest="$4"
    rm -rf "$dest"
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$tag" "$url" "$dest"
    if [ "$(git -C "$dest" rev-parse HEAD)" != "$commit" ]; then
        echo "Le tag $tag de $url ne pointe plus sur $commit, arrêt." >&2
        rm -rf "$dest"
        exit 1
    fi
}

TAG="1.6.20261003"
COMMIT="54f38c0bcde7900bbf69144e084ab0418f640bbc"
DEST="Vendor/libghostty-spm"

STAMP="$COMMIT $(cat Patches/libghostty-spm-*.patch | shasum | cut -d' ' -f1)"
if [ ! -f "$DEST/.brume-stamp" ] || [ "$(cat "$DEST/.brume-stamp")" != "$STAMP" ]; then
    clone_pinned https://github.com/Lakr233/libghostty-spm.git "$TAG" "$COMMIT" "$DEST"
    for patch in Patches/libghostty-spm-*.patch; do
        git -C "$DEST" apply "$PWD/$patch"
    done
    echo "$STAMP" > "$DEST/.brume-stamp"
    echo "libghostty-spm $TAG prêt."
fi

# Greffons zsh embarqués dans l'app et actifs par défaut.
pin_plugin() {
    local name="$1" tag="$2" commit="$3"
    if [ "$(git -C "Vendor/$name" rev-parse HEAD 2>/dev/null)" != "$commit" ]; then
        clone_pinned "https://github.com/zsh-users/$name.git" "$tag" "$commit" "Vendor/$name"
        echo "$name $tag prêt."
    fi
}
pin_plugin zsh-syntax-highlighting 0.8.0 db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e
pin_plugin zsh-autosuggestions v0.7.1 e52ee8ca55bcc56a17c828767a3f98f22a68d4eb

# fastfetch précompilé pour la page d'accueil des terminaux, vérifié par son empreinte.
FASTFETCH_VERSION="2.69.0"
if [ "$(uname -m)" = "arm64" ]; then
    FASTFETCH_ARCH="aarch64"
    FASTFETCH_SHA="3901a90b11f1823a00fea6f3c3c877e7f336465e9d9facc98fd6b8803e8fac7e"
else
    FASTFETCH_ARCH="amd64"
    FASTFETCH_SHA="ec6ea2aed26df0561c9331526f1f4289f4285b11f7e3910c29f0b66766b635f1"
fi
if [ "$(cat Vendor/fastfetch/.version 2>/dev/null)" != "$FASTFETCH_VERSION-$FASTFETCH_ARCH" ]; then
    rm -rf Vendor/fastfetch
    mkdir -p Vendor/fastfetch
    archive="Vendor/fastfetch/fastfetch.tar.gz"
    curl -fsSL -o "$archive" "https://github.com/fastfetch-cli/fastfetch/releases/download/$FASTFETCH_VERSION/fastfetch-macos-$FASTFETCH_ARCH.tar.gz"
    if [ "$(shasum -a 256 "$archive" | cut -d' ' -f1)" != "$FASTFETCH_SHA" ]; then
        echo "fastfetch $FASTFETCH_VERSION : empreinte inattendue, arrêt." >&2
        rm -rf Vendor/fastfetch
        exit 1
    fi
    tar -xzf "$archive" -C Vendor/fastfetch --strip-components 1
    rm "$archive"
    echo "$FASTFETCH_VERSION-$FASTFETCH_ARCH" > Vendor/fastfetch/.version
    echo "fastfetch $FASTFETCH_VERSION prêt."
fi
