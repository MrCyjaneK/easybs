#!/bin/bash
set -euxo pipefail

source /w/build/scripts/linux-config.sh

if [[ ! -d "$STAGING/sysroot" ]]; then
    cp -a "$PREFIX/sysroot" "$STAGING/sysroot"
fi

# GCC crt objects, libgcc, and libstdc++ headers (not in sysroot).
if [[ -d "$PREFIX/lib/gcc" ]]; then
    cp -a "$PREFIX/lib/gcc" "$STAGING/lib/"
fi
if [[ -d "$PREFIX/include/c++" ]]; then
    mkdir -p "$STAGING/include"
    cp -a "$PREFIX/include/c++" "$STAGING/include/"
fi

# Real GCC drivers for clang --gcc-toolchain (kept out of bin/ so gcc->clang symlinks
# used by downstream builds cannot recurse back into the clang wrapper).
GCC_TC="$STAGING/libexec/gcc-toolchain"
mkdir -p "$GCC_TC/bin"
for exe in "${TARGET_TRIPLE}-gcc" "${TARGET_TRIPLE}-g++" "${TARGET_TRIPLE}-cpp"; do
    if [[ -x "$PREFIX/bin/$exe" ]]; then
        cp -a "$PREFIX/bin/$exe" "$GCC_TC/bin/"
    fi
done
ln -sf "${TARGET_TRIPLE}-gcc" "$GCC_TC/bin/gcc"
ln -sf "${TARGET_TRIPLE}-g++" "$GCC_TC/bin/g++"
if [[ -d "$PREFIX/libexec/gcc" ]]; then
    mkdir -p "$GCC_TC/libexec"
    cp -a "$PREFIX/libexec/gcc" "$GCC_TC/libexec/"
fi
if [[ -d "$STAGING/lib/gcc" ]]; then
    mkdir -p "$GCC_TC/lib"
    ln -sf "../../../lib/gcc" "$GCC_TC/lib/gcc"
fi

/w/build/scripts/toybox-install.sh
/w/build/scripts/setup-wrappers.sh

mkdir -p "$DIST"
tar -cJf "$DIST/${ARTIFACT_NAME}.tar.xz" -C "$EASYBS_ROOT/build/staging" "$ARTIFACT_NAME"

ls -lh "$DIST/${ARTIFACT_NAME}.tar.xz"
