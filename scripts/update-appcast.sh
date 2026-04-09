#!/bin/bash
# update-appcast.sh — Add a new release entry to the Sparkle appcast.
#
# Usage: ./scripts/update-appcast.sh <version> <build-number> <dmg-path> <ed-signature>
#
# Arguments:
#   version       Release version (e.g. 1.0.0)
#   build-number  CI build number (e.g. 22) — used as sparkle:version
#   dmg-path      Path to the .dmg file
#   ed-signature  EdDSA signature from Sparkle's sign_update tool
#
# The script updates appcast.xml with the new release entry.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APPCAST="$PROJECT_ROOT/appcast.xml"
GITHUB_REPO="vaultype/VaulType"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") <version> <build-number> <dmg-path> <ed-signature>

Add a new release entry to the Sparkle appcast.

Arguments:
  version       Release version string (e.g. 1.0.0)
  build-number  CI build number (e.g. 22) — maps to sparkle:version (CFBundleVersion)
  dmg-path      Path to the signed .dmg file
  ed-signature  EdDSA signature from: sparkle/bin/sign_update <dmg>

Prerequisites:
  - appcast.xml must exist at project root
  - DMG must be built and signed

Output:
  Updates appcast.xml with the new <item> entry.

Examples:
  ./scripts/update-appcast.sh 1.0.0 22 build/VaulType-1.0.0.dmg "BASE64_SIGNATURE"
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if [[ $# -lt 4 ]]; then
    echo "error: requires 4 arguments: version, build-number, dmg-path, ed-signature"
    echo ""
    usage
    exit 1
fi

VERSION="$1"
BUILD_NUMBER="$2"
DMG_PATH="$3"
ED_SIGNATURE_RAW="$4"

# sign_update may output full attribute string like:
#   sparkle:edSignature="BASE64..." length="12345"
# Extract just the base64 signature value if needed.
if [[ "$ED_SIGNATURE_RAW" == *'sparkle:edSignature="'* ]]; then
    ED_SIGNATURE=$(echo "$ED_SIGNATURE_RAW" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
else
    ED_SIGNATURE="$ED_SIGNATURE_RAW"
fi

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
if [[ ! -f "$APPCAST" ]]; then
    echo "error: appcast.xml not found at: $APPCAST"
    exit 1
fi

if [[ ! -f "$DMG_PATH" ]]; then
    echo "error: DMG not found at: $DMG_PATH"
    exit 1
fi

# Compute file size and publication date
DMG_SIZE=$(stat -f%z "$DMG_PATH")
PUB_DATE=$(date -R)
DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/v${VERSION}/VaulType.dmg"
MIN_SYSTEM_VERSION="14.0"

echo "=== VaulType: Appcast Update ==="
echo ""
echo "Version    : $VERSION"
echo "Build      : $BUILD_NUMBER"
echo "DMG        : $DMG_PATH"
echo "Size       : $DMG_SIZE bytes"
echo "Download   : $DOWNLOAD_URL"
echo ""

# ---------------------------------------------------------------------------
# Build the new <item> XML entry
# ---------------------------------------------------------------------------
# sparkle:version uses the CI build number (CFBundleVersion) for numeric comparison.
# sparkle:shortVersionString uses the marketing version shown to users.
NEW_ITEM=$(cat <<ITEM_EOF
        <item>
            <title>Version ${VERSION}</title>
            <pubDate>${PUB_DATE}</pubDate>
            <sparkle:version>${BUILD_NUMBER}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>${MIN_SYSTEM_VERSION}</sparkle:minimumSystemVersion>
            <enclosure
                url="${DOWNLOAD_URL}"
                length="${DMG_SIZE}"
                type="application/octet-stream"
                sparkle:edSignature="${ED_SIGNATURE}"
            />
        </item>
ITEM_EOF
)

# ---------------------------------------------------------------------------
# Insert the new item before the closing </channel> tag
# ---------------------------------------------------------------------------
# NOTE: Do NOT use sed "r" — on macOS it inserts AFTER the match, placing
# <item> outside </channel> and producing invalid XML that Sparkle silently
# ignores. Use a while-read loop to insert BEFORE </channel>.
TEMP_FILE=$(mktemp)
ITEM_FILE=$(mktemp)
echo "$NEW_ITEM" > "$ITEM_FILE"

while IFS= read -r line; do
    if [[ "$line" == *"</channel>"* ]]; then
        cat "$ITEM_FILE"
    fi
    printf '%s\n' "$line"
done < "$APPCAST" > "$TEMP_FILE"

mv "$TEMP_FILE" "$APPCAST"
rm -f "$ITEM_FILE"

echo "[done] appcast.xml updated with v${VERSION} (build ${BUILD_NUMBER})"
echo ""
echo "Next steps:"
echo "  1. Commit appcast.xml"
echo "  2. Push to gh-pages branch for GitHub Pages deployment"
