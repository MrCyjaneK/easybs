#!/bin/bash
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

SDK="$PREFIX/SDK/MacOSX${SDK_VERSION}.sdk"
CC="$PREFIX/bin/aarch64-apple-darwin-clang"
CXX="$PREFIX/bin/aarch64-apple-darwin-clang++"
LD="$PREFIX/bin/aarch64-apple-darwin-ld"
BUILD_DIR=/w/build/llvm-build-darwin/work

LLVM_SRC=$(ls -d "$SRC/osxcross/build/clang-${CLANG_VERSION}/"*llvm* | head -1)

export PATH="$PREFIX/bin:$PATH"
export MACOSX_DEPLOYMENT_TARGET="$OSX_MIN"
export LD

rm -rf "$BUILD_DIR" "$STAGING"
mkdir -p "$BUILD_DIR" "$STAGING"

cd "$BUILD_DIR"

FUSE_LD="-fuse-ld=$PREFIX/bin/aarch64-apple-darwin-ld"

cmake -G Ninja "$LLVM_SRC/llvm" \
    -DCMAKE_INSTALL_PREFIX=/ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Darwin \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_SYSROOT="$SDK" \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_AR="$PREFIX/bin/aarch64-apple-darwin-ar" \
    -DCMAKE_RANLIB="$PREFIX/bin/aarch64-apple-darwin-ranlib" \
    -DCMAKE_C_FLAGS="-mmacosx-version-min=${OSX_MIN} ${FUSE_LD}" \
    -DCMAKE_CXX_FLAGS="-mmacosx-version-min=${OSX_MIN} -stdlib=libc++ ${FUSE_LD}" \
    -DCMAKE_EXE_LINKER_FLAGS="-isysroot ${SDK} -stdlib=libc++ ${FUSE_LD}" \
    -DCMAKE_SHARED_LINKER_FLAGS="-isysroot ${SDK} -stdlib=libc++ ${FUSE_LD}" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_TARGETS_TO_BUILD=AArch64 \
    -DLLVM_DEFAULT_TARGET_TRIPLE=arm64-apple-darwin \
    -DCLANG_DEFAULT_TARGET_TRIPLE=arm64-apple-darwin \
    -DCLANG_DEFAULT_LINKER=lld \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_ENABLE_ASSERTIONS=OFF

ninja -j"$JOBS"
DESTDIR="$STAGING" ninja install

if [[ -d "$STAGING/usr" ]]; then
    cp -a "$STAGING/usr/." "$STAGING/"
    rm -rf "$STAGING/usr"
fi

if [[ -e "$STAGING/bin/clang++-${CLANG_VERSION}" ]]; then
    :
else
    ln -sf "clang-${CLANG_VERSION}" "$STAGING/bin/clang++-${CLANG_VERSION}"
fi

/w/build/scripts/setup-wrappers.sh

file "$STAGING/bin/clang-${CLANG_VERSION}"
file "$STAGING/bin/clang-${CLANG_VERSION}" | grep -q 'Mach-O.*arm64'
file -L "$STAGING/bin/ld64.lld"
file -L "$STAGING/bin/ld64.lld" | grep -q 'Mach-O.*arm64'
