#!/bin/bash
set -euxo pipefail

source /w/build/scripts/linux-config.sh

HOST_CC=/usr/bin/gcc
SYSROOT="$PREFIX/sysroot"
CC="$PREFIX/bin/${TARGET_TRIPLE}-gcc"
GCC_VER="$($CC -dumpversion)"
GCC_LIB="$PREFIX/lib/gcc/${TARGET_TRIPLE}/${GCC_VER}"
CROSS_CFLAGS="--sysroot=${SYSROOT} -B${PREFIX}/bin -I${PREFIX}/include -I${PREFIX}/include/c++/${GCC_VER} -I${PREFIX}/include/c++/${GCC_VER}/${TARGET_TRIPLE} -I${PREFIX}/usr/include"
CROSS_LDFLAGS="--sysroot=${SYSROOT} -B${PREFIX}/bin -L${SYSROOT}/lib -L${GCC_LIB}"

export CC
export CROSS_COMPILE=""
export HOSTCC="$HOST_CC"
export CFLAGS="$CROSS_CFLAGS"
export LDFLAGS="$CROSS_LDFLAGS"
export NOSTRIP=1

mkdir -p "$STAGING/bin"

toybox_disable_applets() {
    local applet cfg
    for applet in su login mkpasswd; do
        cfg="CONFIG_${applet^^}"
        sed -i "s/${cfg}=y/# ${cfg} is not set/" .config
    done
}

cd "$SRC/toybox"
source /w/build/scripts/toybox-applets.sh
make distclean 2>/dev/null || true
make defconfig
toybox_disable_applets
toybox_enable_applets
make -j"$JOBS" toybox

cp -f toybox "$STAGING/bin/toybox"
chmod 755 "$STAGING/bin/toybox"

file "$STAGING/bin/toybox"
file "$STAGING/bin/toybox" | grep -q "ELF.*${ELF_ARCH}"
