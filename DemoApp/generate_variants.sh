#!/bin/bash
# Generates multiple signed pass variants with random boarding pass data
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
P12_PATH="${1:?Usage: ./generate_variants.sh <p12_path> <p12_password>}"
P12_PASSWORD="${2:?Usage: ./generate_variants.sh <p12_path> <p12_password>}"
OUTPUT_DIR="$SCRIPT_DIR/DemoApp"

GATES=("A1" "A12" "B5" "B22" "C3" "C16" "D7" "D19" "E2" "E14")
SEATS=("1A" "4F" "12F" "15C" "22A" "28D" "33B" "38E" "44A" "51F")
BOARDS=("6:00 AM" "7:30 AM" "8:45 AM" "9:15 AM" "10:00 AM" "11:30 AM" "1:00 PM" "2:45 PM" "4:30 PM" "6:00 PM")
TERMS=("1" "2" "3" "4")
GROUPS=("1" "2" "3" "4" "5")
DATES=("Jun 9" "Jun 10" "Jun 11" "Jun 12" "Jun 15" "Jul 1" "Jul 5" "Aug 3")

for i in $(seq 1 10); do
    GATE=${GATES[$((RANDOM % ${#GATES[@]}))]}
    SEAT=${SEATS[$((RANDOM % ${#SEATS[@]}))]}
    BOARD=${BOARDS[$((RANDOM % ${#BOARDS[@]}))]}
    TERM=${TERMS[$((RANDOM % ${#TERMS[@]}))]}
    GROUP=${GROUPS[$((RANDOM % ${#GROUPS[@]}))]}
    DATE=${DATES[$((RANDOM % ${#DATES[@]}))]}

    WORK_DIR=$(mktemp -d)
    PASS_WORK="$WORK_DIR/pass"
    mkdir -p "$PASS_WORK"

    cat > "$PASS_WORK/pass.json" <<EOF
{
  "formatVersion": 1,
  "passTypeIdentifier": "pass.com.example.WalletPassDemoApp",
  "serialNumber": "DEMO-BP-001",
  "teamIdentifier": "5C45ZNR5KV",
  "organizationName": "Demo Airlines",
  "description": "Boarding Pass",
  "foregroundColor": "rgb(255, 255, 255)",
  "backgroundColor": "rgb(0, 80, 200)",
  "labelColor": "rgb(200, 220, 255)",
  "boardingPass": {
    "transitType": "PKTransitTypeAir",
    "headerFields": [
      {"key": "flight", "label": "FLIGHT", "value": "DA 442"},
      {"key": "date", "label": "DATE", "value": "$DATE"}
    ],
    "primaryFields": [
      {"key": "origin", "label": "CHICAGO", "value": "ORD"},
      {"key": "destination", "label": "TOKYO", "value": "HND"}
    ],
    "secondaryFields": [
      {"key": "passenger", "label": "PASSENGER", "value": "John Doe"}
    ],
    "auxiliaryFields": [
      {"key": "boardingTime", "label": "BOARDS", "value": "$BOARD", "changeMessage": "Boarding time changed to %@"},
      {"key": "terminal", "label": "TERM", "value": "$TERM", "changeMessage": "Terminal changed to %@"},
      {"key": "gate", "label": "GATE", "value": "$GATE", "changeMessage": "Gate changed to %@"},
      {"key": "group", "label": "GROUP", "value": "$GROUP"},
      {"key": "seat", "label": "SEAT", "value": "$SEAT", "changeMessage": "Seat changed to %@"}
    ],
    "backFields": [
      {"key": "info", "label": "Important Information", "value": "Variant $i: Gate $GATE, Seat $SEAT, Boards $BOARD"}
    ]
  },
  "barcode": {
    "message": "DEMO-BP-ORD-HND-DA442-V$i-$GATE-$SEAT",
    "format": "PKBarcodeFormatQR",
    "messageEncoding": "iso-8859-1"
  },
  "barcodes": [
    {
      "message": "DEMO-BP-ORD-HND-DA442-V$i-$GATE-$SEAT",
      "format": "PKBarcodeFormatQR",
      "messageEncoding": "iso-8859-1"
    }
  ]
}
EOF

    # Copy icons
    for f in icon.png icon@2x.png icon@3x.png; do
        if [ -f "$SCRIPT_DIR/PassAssets/$f" ]; then
            cp "$SCRIPT_DIR/PassAssets/$f" "$PASS_WORK/"
        fi
    done

    # Generate manifest
    MANIFEST="$PASS_WORK/manifest.json"
    echo "{" > "$MANIFEST"
    FIRST=true
    for f in "$PASS_WORK"/*; do
        FILENAME=$(basename "$f")
        [ "$FILENAME" = "manifest.json" ] || [ "$FILENAME" = "signature" ] && continue
        HASH=$(openssl sha1 -binary "$f" | xxd -p | tr -d '\n')
        [ "$FIRST" = true ] && FIRST=false || echo "," >> "$MANIFEST"
        printf '  "%s": "%s"' "$FILENAME" "$HASH" >> "$MANIFEST"
    done
    echo "" >> "$MANIFEST"
    echo "}" >> "$MANIFEST"

    # Extract certs
    CERT_PEM="$WORK_DIR/cert.pem"
    KEY_PEM="$WORK_DIR/key.pem"
    WWDR_PEM="$WORK_DIR/wwdr.pem"
    openssl pkcs12 -legacy -in "$P12_PATH" -clcerts -nokeys -passin "pass:$P12_PASSWORD" -out "$CERT_PEM" 2>/dev/null
    openssl pkcs12 -legacy -in "$P12_PATH" -nocerts -passin "pass:$P12_PASSWORD" -passout "pass:temp123" -out "$KEY_PEM" 2>/dev/null
    curl -sL "https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer" -o "$WORK_DIR/wwdr.cer"
    openssl x509 -inform DER -in "$WORK_DIR/wwdr.cer" -out "$WWDR_PEM" 2>/dev/null

    # Sign
    openssl smime -sign -signer "$CERT_PEM" -inkey "$KEY_PEM" -passin "pass:temp123" \
        -certfile "$WWDR_PEM" -in "$PASS_WORK/manifest.json" -out "$PASS_WORK/signature" \
        -outform DER -binary

    # Zip
    OUTPUT_PATH="$OUTPUT_DIR/Variant${i}.pkpass"
    pushd "$PASS_WORK" > /dev/null
    zip -q "$OUTPUT_PATH" ./*
    popd > /dev/null

    rm -rf "$WORK_DIR"
    echo "Created Variant${i}.pkpass (Gate: $GATE, Seat: $SEAT, Boards: $BOARD, Term: $TERM)"
done

echo "==> Done! Generated 10 variants in $OUTPUT_DIR"
