#!/bin/bash
set -euo pipefail

# Capture la fenêtre Brume seule. Usage : bash capture.sh [fichier.png]

OUT="${1:-${TMPDIR:-/tmp}/brume.png}"

# Une fenêtre cachée ou sur un autre bureau sort vide : on la ramène devant.
open -a Brume
sleep 1

ID=$(swift -e 'import CoreGraphics
let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
if let w = windows.first(where: { $0["kCGWindowOwnerName"] as? String == "Brume" && $0["kCGWindowLayer"] as? Int == 0 }) {
    print(w["kCGWindowNumber"]!)
}')
if [ -z "$ID" ]; then
    echo "Aucune fenêtre Brume à l'écran." >&2
    exit 1
fi

screencapture -x -o -l "$ID" "$OUT"
echo "$OUT"
