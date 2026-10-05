#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Compile Brume, assemble Brume.app, signe, installe dans /Applications et relance.
#
# Usage :
#   bash scripts/build-app.sh               # release
#   bash scripts/build-app.sh --debug       # build rapide
#   bash scripts/build-app.sh --no-install  # .build/app/Brume.app seulement, le Brume ouvert reste

APP_NAME="Brume"
BUNDLE_ID="app.brume.Brume"
CERT_NAME="Brume Dev"
VERSION="0.1.0"
# Monté de 1 par scripts/release.sh : Sparkle le compare au `sparkle:version` de l'appcast.
BUILD_NUMBER="1"
FEED_URL="https://raw.githubusercontent.com/jeremy-prt/brume/main/appcast.xml"
# Clé publique EdDSA, partagée avec Orby : la clé privée est dans le trousseau de Jérémy.
SPARKLE_PUBLIC_KEY="4NnmxyV0FR0GIFCf0hShB1k4vSkYsl5D55knxLeopgQ="
BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

CONFIG="release"
INSTALL=1
for arg in "$@"; do
    case "$arg" in
        --debug) CONFIG="debug" ;;
        --no-install) INSTALL=0 ;;
    esac
done

bash scripts/setup.sh

echo "Building ($CONFIG)..."
swift build -c "$CONFIG"
BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"

echo "Creating app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$APP_BUNDLE/Contents/Frameworks"
cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
# Posé par SwiftPM à côté du binaire, trouvé par le rpath de Package.swift.
ditto "$(dirname "$BIN_PATH")/Sparkle.framework" "$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
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

# La page d'accueil des terminaux. Dans Contents/MacOS, où codesign accepte un exécutable de plus.
cp Vendor/fastfetch/usr/bin/fastfetch "$APP_BUNDLE/Contents/MacOS/fastfetch"
cp Vendor/fastfetch/usr/share/licenses/fastfetch/LICENSE "$APP_BUNDLE/Contents/Resources/fastfetch-LICENSE"

# Déclarées par ATSApplicationFontsPath : macOS les charge pour l'app seule, le moteur les trouve.
cp -R Resources/Fonts "$APP_BUNDLE/Contents/Resources/Fonts"

# La licence de Brume et celles des composants embarqués voyagent avec l'app.
cp LICENSE THIRD_PARTY_LICENSES.md "$APP_BUNDLE/Contents/Resources/"

if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Sans fr.lproj, macOS affiche les menus système en anglais.
mkdir -p "$APP_BUNDLE/Contents/Resources/fr.lproj"
touch "$APP_BUNDLE/Contents/Resources/fr.lproj/InfoPlist.strings"

# Ce que macOS affiche quand un programme lancé dans le terminal demande un accès : sans texte,
# certaines demandes sont refusées d'office. Lu par macOS, pas par l'app : hors de TextKey.
PERMISSIONS=(
    "NSDesktopFolderUsageDescription|Un programme lancé dans Brume voudrait accéder au dossier Bureau.|A program running within Brume would like to access your Desktop folder."
    "NSDocumentsFolderUsageDescription|Un programme lancé dans Brume voudrait accéder au dossier Documents.|A program running within Brume would like to access your Documents folder."
    "NSDownloadsFolderUsageDescription|Un programme lancé dans Brume voudrait accéder au dossier Téléchargements.|A program running within Brume would like to access your Downloads folder."
    "NSRemovableVolumesUsageDescription|Un programme lancé dans Brume voudrait accéder aux disques amovibles.|A program running within Brume would like to access removable volumes."
    "NSNetworkVolumesUsageDescription|Un programme lancé dans Brume voudrait accéder aux volumes réseau.|A program running within Brume would like to access network volumes."
    "NSAppleEventsUsageDescription|Un programme lancé dans Brume voudrait utiliser AppleScript.|A program running within Brume would like to use AppleScript."
    "NSAudioCaptureUsageDescription|Un programme lancé dans Brume voudrait accéder au son du système.|A program running within Brume would like to access your system's audio."
    "NSBluetoothAlwaysUsageDescription|Un programme lancé dans Brume voudrait utiliser le Bluetooth.|A program running within Brume would like to use Bluetooth."
    "NSCalendarsUsageDescription|Un programme lancé dans Brume voudrait accéder à votre Calendrier.|A program running within Brume would like to access your Calendar."
    "NSCameraUsageDescription|Un programme lancé dans Brume voudrait utiliser la caméra.|A program running within Brume would like to use the camera."
    "NSContactsUsageDescription|Un programme lancé dans Brume voudrait accéder à vos Contacts.|A program running within Brume would like to access your Contacts."
    "NSLocalNetworkUsageDescription|Un programme lancé dans Brume voudrait accéder au réseau local.|A program running within Brume would like to access the local network."
    "NSLocationUsageDescription|Un programme lancé dans Brume voudrait connaître votre position.|A program running within Brume would like to access your location information."
    "NSMicrophoneUsageDescription|Un programme lancé dans Brume voudrait utiliser le micro.|A program running within Brume would like to use your microphone."
    "NSMotionUsageDescription|Un programme lancé dans Brume voudrait accéder aux données de mouvement.|A program running within Brume would like to access motion data."
    "NSPhotoLibraryUsageDescription|Un programme lancé dans Brume voudrait accéder à votre photothèque.|A program running within Brume would like to access your Photo Library."
    "NSRemindersUsageDescription|Un programme lancé dans Brume voudrait accéder à vos Rappels.|A program running within Brume would like to access your reminders."
    "NSSpeechRecognitionUsageDescription|Un programme lancé dans Brume voudrait utiliser la reconnaissance vocale.|A program running within Brume would like to use speech recognition."
    "NSSystemAdministrationUsageDescription|Un programme lancé dans Brume demande les droits d'administrateur.|A program running within Brume requires elevated privileges."
)
PERMISSION_KEYS=""
mkdir -p "$APP_BUNDLE/Contents/Resources/en.lproj"
for entry in "${PERMISSIONS[@]}"; do
    IFS='|' read -r key french english <<< "$entry"
    PERMISSION_KEYS+="    <key>$key</key>"$'\n'"    <string>$french</string>"$'\n'
    echo "\"$key\" = \"$english\";" >> "$APP_BUNDLE/Contents/Resources/en.lproj/InfoPlist.strings"
done

# Le service du Finder sur un dossier. macOS traduit son titre (NSMenuItem plus bas) par ces fichiers.
# Déclaré par NSSendTypes comme Ghostty : avec NSSendFileTypes seul, le Finder ne le proposait pas.
SERVICE_TITLE="New Brume Tab Here"
echo "\"$SERVICE_TITLE\" = \"$SERVICE_TITLE\";" > "$APP_BUNDLE/Contents/Resources/en.lproj/ServicesMenu.strings"
echo "\"$SERVICE_TITLE\" = \"Nouvel onglet Brume ici\";" > "$APP_BUNDLE/Contents/Resources/fr.lproj/ServicesMenu.strings"

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
    <string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>fr</string>
        <string>en</string>
    </array>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>ATSApplicationFontsPath</key>
    <string>Fonts</string>
    <key>SUFeedURL</key>
    <string>$FEED_URL</string>
    <key>SUPublicEDKey</key>
    <string>$SPARKLE_PUBLIC_KEY</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUScheduledCheckInterval</key>
    <integer>86400</integer>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Folder</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.folder</string>
            </array>
        </dict>
    </array>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>$SERVICE_TITLE</string>
            </dict>
            <key>NSMessage</key>
            <string>openTab</string>
            <key>NSPortName</key>
            <string>$APP_NAME</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSTextContent</key>
                <string>FilePath</string>
            </dict>
            <key>NSSendTypes</key>
            <array>
                <string>NSFilenamesPboardType</string>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
$PERMISSION_KEYS</dict>
</plist>
PLIST

# Un certificat stable garde les permissions macOS (accès Documents, Bureau...) entre
# deux builds. En ad-hoc, l'identité change à chaque build et macOS redemande tout.
IDENTITY="-"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "\"$CERT_NAME\""; then
    echo "Signing with \"$CERT_NAME\"..."
    IDENTITY="$CERT_NAME"
else
    echo "Certificat \"$CERT_NAME\" absent : signature ad-hoc. Lancer une fois : bash scripts/create-dev-cert.sh"
fi
codesign --force -s "$IDENTITY" "$APP_BUNDLE/Contents/MacOS/fastfetch"
# Sparkle de l'intérieur vers l'extérieur, comme le dit sa doc : `--deep` ne garderait pas
# les droits du service de téléchargement.
SPARKLE="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
codesign --force -s "$IDENTITY" "$SPARKLE/Versions/B/XPCServices/Installer.xpc"
codesign --force -s "$IDENTITY" --preserve-metadata=entitlements "$SPARKLE/Versions/B/XPCServices/Downloader.xpc"
codesign --force -s "$IDENTITY" "$SPARKLE/Versions/B/Autoupdate"
codesign --force -s "$IDENTITY" "$SPARKLE/Versions/B/Updater.app"
codesign --force -s "$IDENTITY" "$SPARKLE"
codesign --force -s "$IDENTITY" "$APP_BUNDLE"

if [ "$INSTALL" = 0 ]; then
    echo "Done: $APP_BUNDLE"
    exit 0
fi

INSTALLED="/Applications/$APP_NAME.app"
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5
rm -rf "$INSTALLED"
cp -R "$APP_BUNDLE" /Applications/
xattr -cr "$INSTALLED" 2>/dev/null || true
open "$INSTALLED"
echo "Done."
