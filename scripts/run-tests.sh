#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Les Command Line Tools ont Swift Testing, mais hors des chemins par défaut : le
# helper de découverte de SwiftPM ne lit que les flags de la ligne de commande.
FW="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"

bash scripts/setup.sh
# Elles livrent aussi _Testing_Foundation sans son module Swift : importer Foundation dans un
# test casserait la compilation. Le pont n'apporte rien ici, on le coupe.
exec swift test -Xswiftc -F -Xswiftc "$FW" -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays \
    -Xlinker -rpath -Xlinker "$FW" "$@"
