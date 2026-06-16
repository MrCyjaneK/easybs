#!/bin/bash
# Ad-hoc sign Mach-O binaries for aarch64-apple-darwin (required on Apple Silicon).
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

RCODESIGN="$TOOLS/rcodesign"
[[ -x "$RCODESIGN" ]] || { echo "rcodesign missing at $RCODESIGN (run build/fetch.sh)"; exit 1; }

for bin in "$@"; do
    [[ -f "$bin" ]] || { echo "not a file: $bin"; exit 1; }
    env -u RCODESIGN_VERSION \
        -u RCODESIGN_PKG_URL_aarch64 -u RCODESIGN_PKG_SHA256_aarch64 \
        -u RCODESIGN_PKG_URL_x86_64 -u RCODESIGN_PKG_SHA256_x86_64 \
        "$RCODESIGN" sign "$bin"
done
