#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <MysticGSI.zip> [output-directory]" >&2
    exit 2
fi

ZIP_PATH="$(readlink -f "$1")"
OUT_DIR="${2:-$PWD/out/a52xq/mystic_gsi_inspection}"
OUT_DIR="$(mkdir -p "$OUT_DIR" && cd "$OUT_DIR" && pwd)"
WORK_DIR="$OUT_DIR/work"
ARCHIVE_DIR="$WORK_DIR/archive"
ROOT_DIR="$OUT_DIR/extracted_root"
REPORT="$OUT_DIR/donor_report.txt"

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing dependency: $1" >&2
        exit 1
    }
}

for tool in unzip file sha256sum find sort grep awk; do
    need "$tool"
done

rm -rf "$WORK_DIR" "$ROOT_DIR"
mkdir -p "$ARCHIVE_DIR" "$ROOT_DIR"

{
    echo "MysticGSI donor inspection"
    echo "ZIP: $ZIP_PATH"
    echo "SHA-256: $(sha256sum "$ZIP_PATH" | awk '{print $1}')"
    echo
    unzip -l "$ZIP_PATH"
} >"$REPORT"

unzip -q "$ZIP_PATH" -d "$ARCHIVE_DIR"

IMAGE="$(
    find "$ARCHIVE_DIR" -type f \
        \( -iname "*.img" -o -iname "*.img.xz" -o -iname "*.img.zst" \
           -o -iname "*.img.gz" -o -iname "*.img.lz4" \) \
        -printf "%s|%p\n" | sort -nr | head -n 1 | cut -d'|' -f2-
)"

[ -n "$IMAGE" ] || {
    echo "No image file found." | tee -a "$REPORT" >&2
    exit 1
}

RAW="$WORK_DIR/donor.img"

case "$IMAGE" in
    *.xz) need xz; xz -dc "$IMAGE" >"$RAW" ;;
    *.zst) need zstd; zstd -dc "$IMAGE" >"$RAW" ;;
    *.gz) need gzip; gzip -dc "$IMAGE" >"$RAW" ;;
    *.lz4) need lz4; lz4 -dc "$IMAGE" >"$RAW" ;;
    *) cp --reflink=auto "$IMAGE" "$RAW" ;;
esac

TYPE="$(file -b "$RAW")"
echo "Image: $IMAGE" | tee -a "$REPORT"
echo "Type: $TYPE" | tee -a "$REPORT"

if echo "$TYPE" | grep -qi "Android sparse image"; then
    need simg2img
    simg2img "$RAW" "$WORK_DIR/donor.raw.img"
    mv "$WORK_DIR/donor.raw.img" "$RAW"
    TYPE="$(file -b "$RAW")"
    echo "Converted type: $TYPE" | tee -a "$REPORT"
fi

if echo "$TYPE" | grep -qi "EROFS"; then
    need fsck.erofs
    fsck.erofs --extract="$ROOT_DIR" "$RAW"
elif echo "$TYPE" | grep -Eqi "ext[234] filesystem"; then
    need debugfs
    debugfs -R "rdump / $ROOT_DIR" "$RAW"
else
    echo "Unsupported filesystem: $TYPE" | tee -a "$REPORT" >&2
    exit 1
fi

{
    echo
    echo "Build properties:"
    while IFS= read -r prop; do
        echo
        echo "### $prop"
        grep -E \
          "^(ro\.build\.version\.(release|sdk|incremental|security_patch)|ro\.build\.PDA|ro\.build\.fingerprint|ro\.product\.(model|device|name)|ro\.product\.first_api_level|ro\.vendor\.api_level|ro\.board\.first_api_level|ro\.vndk\.version|ro\.build\.version\.(sem|sep|oneui))=" \
          "$prop" 2>/dev/null || true
    done < <(find "$ROOT_DIR" -type f -name build.prop | sort)

    echo
    echo "Filesystem usage:"
    du -sh "$ROOT_DIR"/* 2>/dev/null | sort -h

    echo
    echo "VINTF files:"
    find "$ROOT_DIR" -path "*/etc/vintf/*" -type f | sort

    echo
    echo "Framework files:"
    find "$ROOT_DIR" -type f \
      \( -name framework.jar -o -name services.jar -o -name sem.jar \
         -o -name framework-res.apk \) \
      -printf "%p|%s bytes\n" | sort

    echo
    echo "Fold-specific indicators:"
    grep -RIlE "foldable|hinge|fold_state|device_state|flex.?mode|sub.?display" \
      "$ROOT_DIR/system" "$ROOT_DIR/system_ext" "$ROOT_DIR/product" \
      2>/dev/null | head -500
} >>"$REPORT"

echo "Extracted root: $ROOT_DIR"
echo "Report: $REPORT"
