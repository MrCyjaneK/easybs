#!/bin/bash
set -euxo pipefail

source /w/build/scripts/linux-config.sh

SYSROOT="$PREFIX/sysroot"
CC="$PREFIX/bin/${TARGET_TRIPLE}-gcc"
CXX="$PREFIX/bin/${TARGET_TRIPLE}-g++"
BUILD_DIR="$EASYBS_ROOT/build/llvm-build-linux/${TARGET_TRIPLE}/work"
LLVM_SRC="$SRC/llvm/llvm"
GCC_VER="$($CC -dumpversion)"
GCC_LIB="$PREFIX/lib/gcc/${TARGET_TRIPLE}/${GCC_VER}"
CROSS_CFLAGS="--sysroot=${SYSROOT} -B${PREFIX}/bin -I${PREFIX}/include -I${PREFIX}/usr/include"
CROSS_CXXFLAGS="--sysroot=${SYSROOT} -B${PREFIX}/bin -I${PREFIX}/include -I${PREFIX}/include/c++/${GCC_VER} -I${PREFIX}/include/c++/${GCC_VER}/${TARGET_TRIPLE} -I${PREFIX}/usr/include"
CROSS_LDFLAGS="--sysroot=${SYSROOT} -B${PREFIX}/bin -L${SYSROOT}/lib -L${SYSROOT}/usr/lib -L${GCC_LIB} -L${PREFIX}/lib64"
if [[ "$TARGET_CPU" == aarch64 ]]; then
    CROSS_LDFLAGS="$CROSS_LDFLAGS -latomic"
fi

HOST_CC=/usr/bin/gcc
HOST_CXX=/usr/bin/g++
HOST_TRIPLE="$($HOST_CC -dumpmachine)"

if [[ "$HOST_TRIPLE" != "$TARGET_TRIPLE" ]]; then
    for tool in as ld ar ranlib nm strip objcopy objdump g++ gcc cpp; do
        ln -sf "${TARGET_TRIPLE}-${tool}" "$PREFIX/bin/${tool}"
    done
fi

ZLIB_SYSROOT_LIB="$SYSROOT/usr/lib/libz.a"
if [[ ! -f "$ZLIB_SYSROOT_LIB" ]]; then
    ZLIB_BUILD="$EASYBS_ROOT/build/zlib-sysroot/${TARGET_TRIPLE}/work"
    ZLIB_TARBALL="$SRC/ct-ng/tarballs/zlib-1.3.1.tar.xz"
    rm -rf "$ZLIB_BUILD"
    mkdir -p "$ZLIB_BUILD"
    tar xf "$ZLIB_TARBALL" -C "$ZLIB_BUILD" --strip-components=1
    cd "$ZLIB_BUILD"
    CC="$CC" \
        AR="$PREFIX/bin/${TARGET_TRIPLE}-ar" \
        RANLIB="$PREFIX/bin/${TARGET_TRIPLE}-ranlib" \
        CFLAGS="$CROSS_CFLAGS -fPIC" \
        LDFLAGS="$CROSS_LDFLAGS" \
        ./configure --prefix="$SYSROOT/usr" --static
    make -j"$JOBS"
    make install
fi
test -f "$SYSROOT/usr/include/zlib.h"
test -f "$ZLIB_SYSROOT_LIB"

CMAKE_EXTRA=(-DLLVM_ENABLE_WERROR=OFF)
if [[ "$HOST_TRIPLE" != "$TARGET_TRIPLE" ]]; then
  CROSS_CXXFLAGS="$CROSS_CXXFLAGS -Wno-suggest-override"
  HOST_TOOLS_DIR="$EASYBS_ROOT/build/llvm-build-linux/host-tools"
  HOST_TOOLS_BUILD="$HOST_TOOLS_DIR/work"
  if [[ ! -x "$HOST_TOOLS_BUILD/bin/llvm-tblgen" || ! -x "$HOST_TOOLS_BUILD/bin/clang-tblgen" ]]; then
    rm -rf "$HOST_TOOLS_BUILD"
    mkdir -p "$HOST_TOOLS_BUILD"
  env -u CFLAGS -u CXXFLAGS -u LDFLAGS \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    cmake -G Ninja -S "$LLVM_SRC" -B "$HOST_TOOLS_BUILD" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER="$HOST_CC" \
        -DCMAKE_CXX_COMPILER="$HOST_CXX" \
        -DLLVM_TARGETS_TO_BUILD="$LLVM_TARGET" \
        -DLLVM_ENABLE_PROJECTS=clang \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF
  env -u CFLAGS -u CXXFLAGS -u LDFLAGS \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    ninja -C "$HOST_TOOLS_BUILD" -j"$JOBS" llvm-tblgen clang-tblgen
  fi

  sed -i 's/^add_subdirectory(Interpreter)$/# cross-build: add_subdirectory(Interpreter)/' \
    "$SRC/llvm/clang/lib/CMakeLists.txt"
  sed -i 's/^  set(HAVE_CLANG_REPL_SUPPORT ON)$/  set(HAVE_CLANG_REPL_SUPPORT OFF)/' \
    "$SRC/llvm/clang/CMakeLists.txt"

  CMAKE_EXTRA+=(
    -DLLVM_USE_HOST_TOOLS=OFF
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF
    -DCLANG_ENABLE_ARCMT=OFF
    -DLLVM_TABLEGEN="$HOST_TOOLS_BUILD/bin/llvm-tblgen"
    -DCLANG_TABLEGEN="$HOST_TOOLS_BUILD/bin/clang-tblgen"
    -DCMAKE_ASM_COMPILER="$PREFIX/bin/${TARGET_TRIPLE}-gcc"
    -DCMAKE_ASM_FLAGS="-B${PREFIX}/bin --sysroot=${SYSROOT} -x assembler-with-cpp"
  )
  NINJA_JOBS=$(nproc)
else
    NINJA_JOBS=$(nproc)
    export PATH="$PREFIX/bin:$PATH"
    export CFLAGS="$CROSS_CFLAGS"
    export CXXFLAGS="$CROSS_CXXFLAGS"
    export LDFLAGS="$CROSS_LDFLAGS"
fi

rm -rf "$BUILD_DIR" "$STAGING"
mkdir -p "$BUILD_DIR" "$STAGING/bin"

cd "$BUILD_DIR"

cmake -G Ninja "$LLVM_SRC" \
    -DCMAKE_INSTALL_PREFIX=/ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CROSSCOMPILING=ON \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR="$TARGET_CPU" \
    -DCMAKE_SYSROOT="$SYSROOT" \
    -DCMAKE_FIND_ROOT_PATH="$SYSROOT" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_AR="$PREFIX/bin/${TARGET_TRIPLE}-ar" \
    -DCMAKE_RANLIB="$PREFIX/bin/${TARGET_TRIPLE}-ranlib" \
    -DCMAKE_LINKER="$CXX" \
    -DCMAKE_C_FLAGS="$CROSS_CFLAGS" \
    -DCMAKE_CXX_FLAGS="$CROSS_CXXFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$CROSS_LDFLAGS" \
    -DCMAKE_SHARED_LINKER_FLAGS="$CROSS_LDFLAGS" \
    -DCMAKE_MODULE_LINKER_FLAGS="$CROSS_LDFLAGS" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_TARGETS_TO_BUILD="$LLVM_TARGET" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DCLANG_DEFAULT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DCLANG_DEFAULT_LINKER=lld \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_ENABLE_ZLIB=FORCE_ON \
    -DZLIB_INCLUDE_DIR="$SYSROOT/usr/include" \
    -DZLIB_LIBRARY="$ZLIB_SYSROOT_LIB" \
    "${CMAKE_EXTRA[@]}"

ninja -j"$NINJA_JOBS" || {
  echo "ninja failed; retrying first failing target with -j1"
  ninja -j1 -k1
  exit 1
}
DESTDIR="$STAGING" ninja install

if [[ -d "$STAGING/usr" ]]; then
    cp -a "$STAGING/usr/." "$STAGING/"
    rm -rf "$STAGING/usr"
fi

ln -sf "clang-${LLVM_VERSION}" "$STAGING/bin/clang-${CLANG_VERSION}"
if [[ -e "$STAGING/bin/clang++-${LLVM_VERSION}" ]]; then
    ln -sf "clang++-${LLVM_VERSION}" "$STAGING/bin/clang++-${CLANG_VERSION}"
else
    ln -sf "clang-${CLANG_VERSION}" "$STAGING/bin/clang++-${CLANG_VERSION}"
fi

/w/build/scripts/setup-wrappers.sh

file "$STAGING/bin/clang-${LLVM_VERSION}"
file "$STAGING/bin/clang-${LLVM_VERSION}" | grep -q "ELF.*${ELF_ARCH}"
file -L "$STAGING/bin/ld.lld"
file -L "$STAGING/bin/ld.lld" | grep -q "ELF.*${ELF_ARCH}"
