#!/usr/bin/env bash
set -euo pipefail

ZIP_NAME="F971BXXU1AZFW_F971BOXM1AZFW_F971BXXU1AZFW_EUX.zip"
AP_NAME="AP_F971BXXU1AZFW_F971BXXU1AZFW_MQB111318164_REV00_user_low_ship_MULTI_CERT_meta_OS17.tar.md5"
BL_NAME="BL_F971BXXU1AZFW_F971BXXU1AZFW_MQB111318164_REV00_user_low_ship_MULTI_CERT.tar.md5"

ZIP_SIZE=24015540826
AP_SIZE=13832601723
BL_SIZE=142868593

ZIP_SHA256="a9d0d2c3d8c5896b43c31d50494f8b2fabb5c7008f181ef4ba0a4f6765487baa"
AP_SHA256="2c3d1d1099d596efddb6d343af85c535c85a2f8ccffdcdd0d24cea928af91bf0"
BL_SHA256="343a70c24f60c8eb6f3a6a1f2f3888e3971e1616fdcd1cedaa62f28dce745c97"

DEFAULT_ZIP="/mnt/g/CodexScratch/f971b-azfw/$ZIP_NAME"
DEFAULT_AP="/mnt/g/CodexScratch/f971b-azfw/ap/$AP_NAME"
DOWNLOADED_BUILD="F971BXXU1AZFW/F971BOXM1AZFW/F971BXXU1AZFW"

VERIFY_ARCHIVE=false
if [[ "${1:-}" == "--verify-archive" ]]; then
    VERIFY_ARCHIVE=true
    shift
fi

FIRMWARE_ZIP="${1:-$DEFAULT_ZIP}"
AP_SOURCE="${2:-$DEFAULT_AP}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE_DIR="$ROOT_DIR/out/odin/SM-F971B_EUX"
AP_DEST="$STAGE_DIR/$AP_NAME"
BL_DEST="$STAGE_DIR/$BL_NAME"
BL_PART="$STAGE_DIR/.$BL_NAME.part"

fail()
{
    echo "ERROR: $*" >&2
    exit 1
}

verify_file()
{
    local file="$1"
    local expected_size="$2"
    local expected_sha256="$3"
    local actual_size
    local actual_sha256

    [ -f "$file" ] || fail "File not found: $file"

    actual_size="$(stat -c %s "$file")"
    [[ "$actual_size" == "$expected_size" ]] ||
        fail "Unexpected size for $file: $actual_size"

    actual_sha256="$(sha256sum "$file" | cut -d " " -f 1)"
    [[ "$actual_sha256" == "$expected_sha256" ]] ||
        fail "SHA-256 mismatch for $file"
}

[ -f "$ROOT_DIR/unica/configs/version.sh" ] ||
    fail "Run this helper from a complete UN1CA checkout"

for tool in sha256sum stat unzip realpath ln mv; do
    command -v "$tool" >/dev/null 2>&1 || fail "Required tool not found: $tool"
done

FIRMWARE_ZIP="$(realpath "$FIRMWARE_ZIP")"
AP_SOURCE="$(realpath "$AP_SOURCE")"

if $VERIFY_ARCHIVE; then
    echo "Verifying full firmware archive..."
    verify_file "$FIRMWARE_ZIP" "$ZIP_SIZE" "$ZIP_SHA256"
fi

echo "Verifying AP archive..."
verify_file "$AP_SOURCE" "$AP_SIZE" "$AP_SHA256"

mkdir -p "$STAGE_DIR"

if [ -e "$AP_DEST" ] || [ -L "$AP_DEST" ]; then
    echo "Verifying staged AP archive..."
    verify_file "$AP_DEST" "$AP_SIZE" "$AP_SHA256"
else
    ln -s "$AP_SOURCE" "$AP_DEST"
fi

if [ -e "$BL_DEST" ]; then
    echo "Verifying staged BL archive..."
    verify_file "$BL_DEST" "$BL_SIZE" "$BL_SHA256"
else
    echo "Extracting BL archive..."
    rm -f "$BL_PART"
    trap 'rm -f "$BL_PART"' EXIT
    unzip -p "$FIRMWARE_ZIP" "$BL_NAME" > "$BL_PART"
    verify_file "$BL_PART" "$BL_SIZE" "$BL_SHA256"
    mv "$BL_PART" "$BL_DEST"
    trap - EXIT
fi

printf "%s" "$DOWNLOADED_BUILD" > "$STAGE_DIR/.downloaded.part"
mv "$STAGE_DIR/.downloaded.part" "$STAGE_DIR/.downloaded"

echo
echo "Fold8 donor staged successfully:"
echo "  $STAGE_DIR"
echo
echo "Next source-only command:"
echo "  source buildenv.sh a52xq"
echo "  unica extract_fw --ignore-target"
