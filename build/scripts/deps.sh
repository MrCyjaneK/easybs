#!/bin/bash
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include"

# libtapi
cd "$SRC/libtapi"
INSTALLPREFIX="$PREFIX" ./build.sh
INSTALLPREFIX="$PREFIX" ./install.sh

# xar
cd "$SRC/xar/xar"
CFLAGS="-w" ./configure --prefix="$PREFIX" --with-bzip2 --with-lzma="$PREFIX"
make -j"$JOBS"
make install
mkdir -p "$PREFIX/include"

# pbzx
cc -O2 -Wall \
    -I "$PREFIX/include" -L "$PREFIX/lib" \
    "$SRC/pbzx/pbzx.c" -o "$PREFIX/bin/pbzx" \
    -llzma -lxar -Wl,-rpath,"$PREFIX/lib"

# cctools-port
cd "$SRC/cctools-port"
sed -i.bak '3182d' cctools/configure
cd cctools
./configure \
    --prefix="$PREFIX" \
    --target=aarch64-apple-darwin \
    --with-libtapi="$PREFIX" \
    --with-libxar="$PREFIX" \
    CC=clang CXX=clang++
make -j"$JOBS"
make install
