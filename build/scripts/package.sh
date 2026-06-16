#!/bin/bash
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

mkdir -p "$STAGING/SDK"
if [[ ! -d "$STAGING/SDK/MacOSX${SDK_VERSION}.sdk" ]]; then
    cp -a "$PREFIX/SDK/MacOSX${SDK_VERSION}.sdk" "$STAGING/SDK/"
fi

/w/build/scripts/toybox-install.sh
/w/build/scripts/setup-wrappers.sh

mkdir -p "$DIST"
tar -cJf "$DIST/${ARTIFACT_NAME}.tar.xz" -C "$EASYBS_ROOT/build/staging" "$ARTIFACT_NAME"

ls -lh "$DIST/${ARTIFACT_NAME}.tar.xz"
