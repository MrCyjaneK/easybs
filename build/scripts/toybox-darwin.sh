#!/bin/bash
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

SDK="$PREFIX/SDK/MacOSX${SDK_VERSION}.sdk"
CC="$PREFIX/bin/aarch64-apple-darwin-clang"
FUSE_LD="-fuse-ld=$PREFIX/bin/aarch64-apple-darwin-ld"

export CC
export CROSS_COMPILE=""
export HOSTCC=gcc
export CFLAGS="-mmacosx-version-min=${OSX_MIN} -isysroot ${SDK} ${FUSE_LD}"
export LDFLAGS="-isysroot ${SDK} ${FUSE_LD} -Wl,-headerpad,0x1000"
export LDOPTIMIZE="-Wl,-dead_strip"
export NOSTRIP=1

mkdir -p "$STAGING/bin"

cd "$SRC/toybox"
source /w/build/scripts/toybox-applets.sh
make distclean 2>/dev/null || true
make macos_defconfig
toybox_enable_applets
make -j"$JOBS" toybox

cp -f toybox "$STAGING/bin/toybox"
chmod 755 "$STAGING/bin/toybox"
/w/build/scripts/codesign-darwin.sh "$STAGING/bin/toybox"

file "$STAGING/bin/toybox"
file "$STAGING/bin/toybox" | grep -q 'Mach-O.*arm64'
