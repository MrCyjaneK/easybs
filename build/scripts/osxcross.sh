#!/bin/bash
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

cd "$SRC/osxcross"

export SKIP_BUILD_XAR=yes
export SKIP_BUILD_P7ZIP=yes
export SKIP_BUILD_PBXZ=yes
export SKIP_GIT=yes
export SKIP_DOWNLOAD=yes
export ENABLE_FULL_BOOTSTRAP=yes
export SKIP_TAPI_BUILD=yes
export SKIP_CCTOOLS_BUILD=yes
export PORTABLE=1
export UNATTENDED=1
export COMPRESSLEVEL=6
export TARGET_DIR="$PREFIX/"
export OCDEBUG=1

sed -i.bak "s|--with-libtapi=\$TARGET_DIR|--with-libtapi=$PREFIX|g" build.sh
sed -i.bak "s|--with-libxar=\$TARGET_DIR|--with-libxar=$PREFIX|g" build.sh

mv "$PREFIX/share/xcode-sdk/"*"${SDK_VERSION}"* tarballs/

# Host toolchain only — prefix/bin has darwin ld symlinks that break stage1.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export CC=clang CXX=clang++

set +o pipefail
yes | INSTALLPREFIX="$PREFIX" ./build_apple_clang.sh
set -o pipefail

cd build/clang-"$CLANG_VERSION"/build_stage3
make install -j"$JOBS"

cd "$SRC/osxcross"
sed -i.bak 's/## Compiler test ##/exit 0/g' build.sh
export PATH="$PREFIX/bin:$PATH"
TARGET_DIR="$PREFIX" bash -x ./build.sh

rm -f "$PREFIX"/bin/*pkg-config

# Drop LLVM build trees; keep extracted sources for clang-darwin.sh.
rm -rf "$SRC/osxcross/build/clang-${CLANG_VERSION}"/build_stage*

"$PREFIX/bin/aarch64-apple-darwin-clang" --version
file "$PREFIX/bin/aarch64-apple-darwin-clang"
