#!/bin/bash
set -euxo pipefail

source /w/build/scripts/linux-config.sh

HOST_CC=/usr/bin/gcc
SYSROOT="$PREFIX/sysroot"
CC="$PREFIX/bin/${TARGET_TRIPLE}-gcc"
GCC_VER="$($CC -dumpversion)"
GCC_LIB="$PREFIX/lib/gcc/${TARGET_TRIPLE}/${GCC_VER}"
CROSS_CFLAGS="--sysroot=${SYSROOT} -B${PREFIX}/bin -I${PREFIX}/include -I${PREFIX}/usr/include"
CROSS_LDFLAGS="--sysroot=${SYSROOT} -B${PREFIX}/bin -L${SYSROOT}/lib -L${GCC_LIB}"

cd "$SRC/dash"
./autogen.sh 2>/dev/null || true

BUILD="$($HOST_CC -dumpmachine)"
if [[ "$BUILD" == "$TARGET_TRIPLE" ]]; then
    BUILD="$TARGET_BUILD"
fi

./configure \
    --host="$TARGET_TRIPLE" \
    --build="$BUILD" \
    --prefix=/ \
    CC_FOR_BUILD="$HOST_CC" \
    CC="$CC" \
    CFLAGS="$CROSS_CFLAGS" \
    LDFLAGS="$CROSS_LDFLAGS"

make -j"$JOBS"
DESTDIR="$STAGING" make install

if [[ -d "$STAGING/usr/bin" ]]; then
    cp -a "$STAGING/usr/bin/dash" "$STAGING/bin/"
    rm -rf "$STAGING/usr"
fi

file -L "$STAGING/bin/dash"
file -L "$STAGING/bin/dash" | grep -q "ELF.*${ELF_ARCH}"
