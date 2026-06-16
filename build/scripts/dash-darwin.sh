#!/bin/bash
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

SDK="$PREFIX/SDK/MacOSX${SDK_VERSION}.sdk"
CC="$PREFIX/bin/aarch64-apple-darwin-clang"
FUSE_LD="-fuse-ld=$PREFIX/bin/aarch64-apple-darwin-ld"

cd "$SRC/dash"
./autogen.sh 2>/dev/null || true

./configure \
    --host=aarch64-apple-darwin \
    --build="$(gcc -dumpmachine)" \
    --prefix=/ \
    CC="$CC" \
    CFLAGS="-mmacosx-version-min=${OSX_MIN} -isysroot ${SDK} ${FUSE_LD}" \
    LDFLAGS="-isysroot ${SDK} ${FUSE_LD}"

make -j"$JOBS"
DESTDIR="$STAGING" make install

if [[ -d "$STAGING/usr/bin" ]]; then
    cp -a "$STAGING/usr/bin/dash" "$STAGING/bin/"
    rm -rf "$STAGING/usr"
fi

file -L "$STAGING/bin/dash"
file -L "$STAGING/bin/dash" | grep -q 'Mach-O.*arm64'
