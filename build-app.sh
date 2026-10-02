#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Compile Brume, assemble Brume.app, signe, installe dans /Applications et relance.
#
# Usage :
#   bash build-app.sh            # release
#   bash build-app.sh --debug    # build rapide

APP_NAME="Brume"
BUNDLE_ID="com.jeremy.brume"
CERT_NAME="Brume Dev"
VERSION="0.1.0"
BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

CONFIG="release"
if [ "${1:-}" = "--debug" ]; then
    CONFIG="debug"
fi

bash setup.sh

echo "Building ($CONFIG)..."
swift build -c "$CONFIG"
BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"

echo "Creating app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
# Dans Contents/Resources : codesign refuse tout ajout à la racine de l'app (voir Patches/).
cp -R "$(dirname "$BIN_PATH")"/*.bundle "$APP_BUNDLE/Contents/Resources/"

mkdir -p "$APP_BUNDLE/Contents/Resources/zsh"
# Seulement ce qui tourne : les README de zsh-syntax-highlighting sont des liens vers docs/,
# que codesign refuse une fois cassés.
for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
    rsync -a --prune-empty-dirs --exclude .git --exclude tests --exclude test-data --exclude src --exclude spec \
        --include '*/' --include '*.zsh' --include .version --include .revision-hash --include VERSION \
        --include COPYING.md --include LICENSE --exclude '*' \
        "Vendor/$plugin" "$APP_BUNDLE/Contents/Resources/zsh/"
done

if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Sans fr.lproj, macOS affiche les menus système en anglais.
mkdir -p "$APP_BUNDLE/Contents/Resources/fr.lproj"
touch "$APP_BUNDLE/Contents/Resources/fr.lproj/InfoPlist.strings"

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>fr</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>fr</string>
    </array>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Un certificat stable garde les permissions macOS (accès Documents, Bureau...) entre
# deux builds. En ad-hoc, l'identité change à chaque build et macOS redemande tout.
if security find-identity -v -p codesigning 2>/dev/null | grep -q "\"$CERT_NAME\""; then
    echo "Signing with \"$CERT_NAME\"..."
    codesign --force --deep -s "$CERT_NAME" "$APP_BUNDLE"
else
    echo "Certificat \"$CERT_NAME\" absent : signature ad-hoc. Lancer une fois : bash create-dev-cert.sh"
    codesign --force --deep -s - "$APP_BUNDLE"
fi

INSTALLED="/Applications/$APP_NAME.app"
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5
rm -rf "$INSTALLED"
cp -R "$APP_BUNDLE" /Applications/
xattr -cr "$INSTALLED" 2>/dev/null || true
open "$INSTALLED"
echo "Done."
