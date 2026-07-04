#!/usr/bin/env bash
set -euo pipefail

required=(
    python3 unzip file sha256sum find grep awk
    xz zstd gzip lz4 simg2img fsck.erofs debugfs
)

missing=0

for tool in "${required[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "OK      %s\n" "$tool"
    else
        printf "MISSING %s\n" "$tool"
        missing=1
    fi
done

if [ "$missing" -ne 0 ]; then
    echo
    echo "Ubuntu packages:"
    echo "sudo apt install python3 unzip file coreutils findutils grep gawk xz-utils zstd gzip lz4 android-sdk-libsparse-utils erofs-utils e2fsprogs"
    exit 1
fi
