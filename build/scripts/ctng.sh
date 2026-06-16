#!/bin/bash
set -euxo pipefail

source /w/build/scripts/linux-config.sh

CTNG_TARBALLS="$SRC/ct-ng/tarballs"
WDIR="$EASYBS_ROOT/build/ctng-cache/${TARGET_TRIPLE}/work"
TOOL_TARGET="$TARGET_TRIPLE"

mkdir -p "$PREFIX/bin" "$PREFIX/sysroot" "$CTNG_TARBALLS" "$WDIR"

cd "$SRC/crosstool-ng"
./bootstrap
./configure --prefix="$PREFIX"
make -j"$JOBS"
make install

export PATH="$PREFIX/bin:$PATH"
export NATIVEPREFIX="$PREFIX"

put_new_config() {
    (grep -v "^${1}=" "$WDIR/.config" || true) >"$WDIR/.config.new"
    mv "$WDIR/.config.new" "$WDIR/.config"
    echo "${1}=${2}" >>"$WDIR/.config"
}

cp "$SRC/ct-ng-configs/platforms/$TOOL_TARGET/.config" "$WDIR/.config"

put_new_config CT_CC_LANG_CXX y
put_new_config CT_MULTILIB n
put_new_config CT_OMIT_TARGET_VENDOR y
put_new_config CT_BINUTILS_EXTRA_CONFIG_ARRAY '"--with-system-zlib"'
put_new_config CT_CC_GCC_SYSTEM_ZLIB y
put_new_config CT_GDB_CROSS n
put_new_config CT_GDB n
put_new_config CT_GDB_NATIVE n
put_new_config CT_GDB_GDBSERVER n
put_new_config CT_DEBUG_GDB n
put_new_config CT_PREFIX_DIR_RO n
put_new_config CT_PREFIX "$NATIVEPREFIX"
put_new_config CT_SYSROOT_DIR "$PREFIX/sysroot"
put_new_config CT_LOCAL_TARBALLS_DIR "$CTNG_TARBALLS"
put_new_config CT_LOG_LEVEL_MAX '"ALL"'
put_new_config CT_CC_LANG_GOLANG n
put_new_config CT_EXPERIMENTAL y
put_new_config CT_ALLOW_BUILD_AS_ROOT y
put_new_config CT_ALLOW_BUILD_AS_ROOT_SURE y
put_new_config CT_FORBID_DOWNLOAD y
put_new_config CT_WANTS_STATIC_LINK n
put_new_config CT_WANTS_STATIC_LINK_CXX n
put_new_config CT_STATIC_TOOLCHAIN n

unset LD_LIBRARY_PATH LIBRARY_PATH CFLAGS CC CXX

cd "$WDIR"
ct-ng build

if [[ -d "$PREFIX/$TOOL_TARGET/$TOOL_TARGET" ]]; then
    cp -a "$PREFIX/$TOOL_TARGET/$TOOL_TARGET/." "$PREFIX/"
    rm -rf "$PREFIX/$TOOL_TARGET/$TOOL_TARGET"
fi

if [[ -d "$PREFIX/$TOOL_TARGET" ]]; then
    cp -an "$PREFIX/$TOOL_TARGET/." "$PREFIX/" 2>/dev/null || cp -a "$PREFIX/$TOOL_TARGET/." "$PREFIX/"
fi

mkdir -p "$PREFIX/bin"

if [[ -d "$PREFIX/$TOOL_TARGET/bin" ]]; then
    cp -a "$PREFIX/$TOOL_TARGET/bin/." "$PREFIX/bin/"
fi

# Drop unprefixed tool symlinks; they break host builds when PREFIX/bin is on PATH.
rm -f "$PREFIX/bin"/{ld,as,ar,gcc,g++,cpp,nm,ranlib,strip,objcopy,objdump,readelf,gprof,addr2line,c++filt,elfedit,gold,size,strings}

test -x "$PREFIX/bin/${TOOL_TARGET}-gcc"
test -d "$PREFIX/sysroot"
"$PREFIX/bin/${TOOL_TARGET}-gcc" --version
file "$PREFIX/bin/${TOOL_TARGET}-gcc"
