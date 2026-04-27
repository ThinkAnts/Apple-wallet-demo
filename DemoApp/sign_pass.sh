#!/bin/bash
# Signs a .pkpass bundle for Apple Wallet
# Usage: ./sign_pass.sh <p12_path> <p12_password> [output_path]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS_DIR="$SCRIPT_DIR/PassAssets"
P12_PATH="${1:?Usage: ./sign_pass.sh <p12_path> <p12_password> [output_path]}"
P12_PASSWORD="${2:?Usage: ./sign_pass.sh <p12_path> <p12_password> [output_path]}"
OUTPUT_PATH="${3:-$SCRIPT_DIR/DemoApp/BoardingPass.pkpass}"

WORK_DIR=$(mktemp -d)
PASS_WORK="$WORK_DIR/pass"

echo "==> Preparing pass bundle..."
mkdir -p "$PASS_WORK"
cp "$PASS_DIR/pass.json" "$PASS_WORK/"

# Copy icon files if they exist
for f in icon.png icon@2x.png icon@3x.png logo.png logo@2x.png; do
    if [ -f "$PASS_DIR/$f" ]; then
        cp "$PASS_DIR/$f" "$PASS_WORK/"
    fi
done

# Generate manifest.json (SHA1 hashes of all files)
echo "==> Generating manifest..."
MANIFEST="$PASS_WORK/manifest.json"
echo "{" > "$MANIFEST"
FIRST=true
for f in "$PASS_WORK"/*; do
    FILENAME=$(basename "$f")
    if [ "$FILENAME" = "manifest.json" ] || [ "$FILENAME" = "signature" ]; then
        continue
    fi
    HASH=$(openssl sha1 -binary "$f" | xxd -p | tr -d '\n')
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo "," >> "$MANIFEST"
    fi
    printf '  "%s": "%s"' "$FILENAME" "$HASH" >> "$MANIFEST"
done
echo "" >> "$MANIFEST"
echo "}" >> "$MANIFEST"

# Extract certificate and key from .p12
echo "==> Extracting signing credentials..."
CERT_PEM="$WORK_DIR/cert.pem"
KEY_PEM="$WORK_DIR/key.pem"

openssl pkcs12 -legacy -in "$P12_PATH" -clcerts -nokeys -passin "pass:$P12_PASSWORD" -out "$CERT_PEM" 2>/dev/null
openssl pkcs12 -legacy -in "$P12_PATH" -nocerts -passin "pass:$P12_PASSWORD" -passout "pass:temp123" -out "$KEY_PEM" 2>/dev/null

# Download WWDR certificate if not cached
WWDR_PEM="$WORK_DIR/wwdr.pem"
WWDR_URL="https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer"
echo "==> Fetching WWDR certificate..."
curl -sL "$WWDR_URL" -o "$WORK_DIR/wwdr.cer"
openssl x509 -inform DER -in "$WORK_DIR/wwdr.cer" -out "$WWDR_PEM" 2>/dev/null

# Sign the manifest
echo "==> Signing pass..."
openssl smime -sign \
    -signer "$CERT_PEM" \
    -inkey "$KEY_PEM" \
    -passin "pass:temp123" \
    -certfile "$WWDR_PEM" \
    -in "$PASS_WORK/manifest.json" \
    -out "$PASS_WORK/signature" \
    -outform DER \
    -binary

# Create .pkpass (zip)
echo "==> Creating .pkpass..."
mkdir -p "$(dirname "$OUTPUT_PATH")"
pushd "$PASS_WORK" > /dev/null
zip -q "$OUTPUT_PATH" ./*
popd > /dev/null

# Cleanup
rm -rf "$WORK_DIR"

echo "==> Done! Pass created at: $OUTPUT_PATH"
