#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Les Command Line Tools ont Swift Testing, mais hors des chemins par défaut : le
# helper de découverte de SwiftPM ne lit que les flags de la ligne de commande.
FW="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"

bash setup.sh
exec swift test -Xswiftc -F -Xswiftc "$FW" -Xlinker -rpath -Xlinker "$FW" "$@"
