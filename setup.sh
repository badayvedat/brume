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
