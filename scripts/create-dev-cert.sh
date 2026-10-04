#!/bin/bash
set -euo pipefail

# Crée le certificat auto-signé « Brume Dev » dans le trousseau login, une fois par
# machine. scripts/build-app.sh signe avec lui pour que macOS garde les permissions entre
# deux builds.

CERT_NAME="Brume Dev"
LOGIN_KC="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -q "\"$CERT_NAME\""; then
    echo "Identité \"$CERT_NAME\" déjà présente."
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/cert.conf" << EOF
[ req ]
distinguished_name = req_dn
x509_extensions = v3_codesign
prompt = no
[ req_dn ]
CN = $CERT_NAME
[ v3_codesign ]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$WORK/brume.key" -out "$WORK/brume.crt" \
    -config "$WORK/cert.conf"

# Sans -legacy, l'import du trousseau refuse le PKCS12 d'OpenSSL 3 (« MAC verification failed »).
openssl pkcs12 -export -legacy -name "$CERT_NAME" \
    -inkey "$WORK/brume.key" -in "$WORK/brume.crt" \
    -out "$WORK/brume.p12" -passout pass:brume

security import "$WORK/brume.p12" -k "$LOGIN_KC" -P "brume" -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k "$LOGIN_KC" "$WORK/brume.crt"

security find-identity -v -p codesigning | grep "$CERT_NAME"
