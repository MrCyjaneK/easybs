#!/bin/bash
set -euxo pipefail

cd "$(dirname "$0")/.."
export EASYBS_ROOT="$PWD"
source build/config.sh

sha256_check() {
    local expected=$1 file=$2
    if command -v sha256sum >/dev/null 2>&1; then
        echo "$expected  $file" | sha256sum -c -
    else
        echo "$expected  $file" | shasum -a 256 -c -
    fi
}

FLAVOR="${1:-clang21-aarch64-apple-darwin}"

mkdir -p "$SRC"

git_clone() {
    local url=$1 sha=$2 dest=$3
    if [[ -d "$dest/.git" ]] && [[ "$(git -C "$dest" rev-parse HEAD)" == "$sha" ]]; then
        echo "$dest already at $sha"
        return
    fi
    rm -rf "$dest"
    git clone "$url" "$dest"
    git -C "$dest" checkout "$sha"
}

download() {
    local url=$1 sha256=$2 dest=$3
    if [[ -f "$dest" ]]; then
        echo "$dest exists"
        if [[ "$sha256" != skip ]]; then
            sha256_check "$sha256" "$dest"
        fi
        return
    fi
    local i
    for i in 1 2 3 4 5; do
        if curl -fsSL "$url" -o "$dest"; then
            break
        fi
        echo "download failed, retry $i..."
        sleep $((i * 30))
    done
    if [[ "$sha256" != skip ]]; then
        sha256_check "$sha256" "$dest"
    fi
}

fetch_common() {
    download "$DASH_URL" skip "$SRC/dash.tar.gz"
    rm -rf "$SRC/dash"
    mkdir -p "$SRC/dash"
    tar xf "$SRC/dash.tar.gz" -C "$SRC/dash" --strip-components=1

    download "$TOYBOX_URL" "$TOYBOX_SHA256" "$SRC/toybox.tar.gz"
    rm -rf "$SRC/toybox"
    mkdir -p "$SRC/toybox"
    tar xf "$SRC/toybox.tar.gz" -C "$SRC/toybox" --strip-components=1
}

fetch_darwin() {
    mkdir -p "$SRC/osxcross/tarballs"

    git_clone https://github.com/MrCyjaneK/osxcross.git "$OSXCROSS_SHA" "$SRC/osxcross"
    git_clone https://github.com/tpoechtrager/cctools-port.git "$CCTOOLS_SHA" "$SRC/cctools-port"
    git_clone https://github.com/tpoechtrager/apple-libtapi.git "$LIBTAPI_SHA" "$SRC/libtapi"
    git_clone https://github.com/tpoechtrager/xar.git "$XAR_SHA" "$SRC/xar"

    download \
        "https://github.com/tpoechtrager/pbzx/archive/${PBZX_SHA}.tar.gz" \
        a9b3e9f29d9f020f75e4edf203359fbed6c1b0d2085f386bf770feaf07ae1694 \
        "$SRC/pbzx.tar.gz"
    rm -rf "$SRC/pbzx"
    mkdir -p "$SRC/pbzx"
    tar xf "$SRC/pbzx.tar.gz" -C "$SRC/pbzx" --strip-components=1

    download "$LLVM_URL" "$LLVM_SHA256" "$SRC/osxcross/tarballs/llvmorg-20.1.8.zip"
    download "$APPLE_LLVM_URL" "$APPLE_LLVM_SHA256" "$SRC/osxcross/tarballs/20250402.zip"

    mkdir -p "$TOOLS"
    case "$(uname -m)" in
        aarch64|arm64)
            rcodesign_url=$RCODESIGN_PKG_URL_aarch64
            rcodesign_sha=$RCODESIGN_PKG_SHA256_aarch64
            ;;
        x86_64|amd64)
            rcodesign_url=$RCODESIGN_PKG_URL_x86_64
            rcodesign_sha=$RCODESIGN_PKG_SHA256_x86_64
            ;;
        *)
            echo "unsupported host arch for rcodesign: $(uname -m)" >&2
            exit 1
            ;;
    esac
    download "$rcodesign_url" "$rcodesign_sha" "$TOOLS/rcodesign.tar.gz"
    rcodesign_tmp=$(mktemp -d)
    tar xzf "$TOOLS/rcodesign.tar.gz" -C "$rcodesign_tmp"
    install -m755 "$rcodesign_tmp"/*/rcodesign "$TOOLS/rcodesign"
    rm -rf "$rcodesign_tmp"
    chmod +x "$TOOLS/rcodesign"
    rm -f "$TOOLS/rcodesign.tar.gz"
}

fetch_linux() {
    local tb="$SRC/ct-ng/tarballs"
    mkdir -p "$tb"

    git_clone https://github.com/crosstool-ng/crosstool-ng.git "$CROSSTOOL_NG_SHA" "$SRC/crosstool-ng"
    git_clone https://github.com/MrCyjaneK/ct-ng-configs.git "$CT_NG_CONFIGS_SHA" "$SRC/ct-ng-configs"

    download \
        https://ftpmirror.gnu.org/gnu/binutils/binutils-2.45.tar.xz \
        c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2 \
        "$tb/binutils-2.45.tar.xz"
    download \
        http://ftpmirror.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz \
        438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e \
        "$tb/gcc-15.2.0.tar.xz"
    download \
        http://ftpmirror.gnu.org/gnu/glibc/glibc-2.41.tar.xz \
        a5a26b22f545d6b7d7b3dd828e11e428f24f4fac43c934fb071b6a7d0828e901 \
        "$tb/glibc-2.41.tar.xz"
    download \
        https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.20.17.tar.xz \
        d011245629b980d4c15febf080b54804aaf215167b514a3577feddb2495f8a3e \
        "$tb/linux-4.20.17.tar.xz"
    download \
        http://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz \
        a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898 \
        "$tb/gmp-6.3.0.tar.xz"
    download \
        http://ftpmirror.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz \
        b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01 \
        "$tb/mpfr-4.2.2.tar.xz"
    download \
        http://ftpmirror.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz \
        ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8 \
        "$tb/mpc-1.3.1.tar.gz"
    download \
        https://libisl.sourceforge.io/isl-0.27.tar.xz \
        6d8babb59e7b672e8cb7870e874f3f7b813b6e00e6af3f8b04f7579965643d5c \
        "$tb/isl-0.27.tar.xz"
    download \
        http://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz \
        354552544b8f99012e5062f7d570ec77f14b412a3ff5c7d8d0dae62c0d217c30 \
        "$tb/expat-2.7.1.tar.xz"
    download \
        http://ftpmirror.gnu.org/gnu/gettext/gettext-0.26.tar.xz \
        d1fb86e260cfe7da6031f94d2e44c0da55903dbae0a2fa0fae78c91ae1b56f00 \
        "$tb/gettext-0.26.tar.xz"
    download \
        http://ftpmirror.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz \
        136d91bc269a9a5785e5f9e980bc76ab57428f604ce3e5a5a90cebc767971cc6 \
        "$tb/ncurses-6.5.tar.gz"
    download \
        https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.xz \
        38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32 \
        "$tb/zlib-1.3.1.tar.xz"
    download \
        https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz \
        eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3 \
        "$tb/zstd-1.5.7.tar.gz"
    download \
        https://ftpmirror.gnu.org/gnu/libiconv/libiconv-1.18.tar.gz \
        3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8 \
        "$tb/libiconv-1.18.tar.gz"

    download "$LLVM_URL" "$LLVM_SHA256" "$SRC/llvmorg-20.1.8.zip"
    rm -rf "$SRC/llvm"
    mkdir -p "$SRC/llvm"
    unzip -q "$SRC/llvmorg-20.1.8.zip" -d "$SRC/llvm"
    mv "$SRC/llvm"/llvm-project-*/* "$SRC/llvm/"
    rmdir "$SRC/llvm"/llvm-project-* 2>/dev/null || true
}

case "$FLAVOR" in
    clang21-aarch64-apple-darwin)
        fetch_common
        fetch_darwin
        ;;
    clang21-aarch64-linux-gnu|clang21-x86_64-linux-gnu)
        fetch_common
        fetch_linux
        ;;
    *)
        echo "unknown flavor: $FLAVOR" >&2
        exit 1
        ;;
esac

echo "sources ready in $SRC (flavor=$FLAVOR)"
