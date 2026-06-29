#!/bin/bash
# Shared pinned versions and paths. Set EASYBS_ROOT on the host; defaults to /w in Docker.

EASYBS_ROOT="${EASYBS_ROOT:-/w}"

export PREFIX="$EASYBS_ROOT/build/prefix"
export SRC="$EASYBS_ROOT/build/src"
export TOOLS="$EASYBS_ROOT/build/tools"
export DIST="$EASYBS_ROOT/dist"

export LLVM_URL=https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-20.1.8.zip
export LLVM_SHA256=b115ce6285dd9f3f401459912c12d28eb2e2d81e2387a71f6300aa11f7bc3288
export LLVM_VERSION=20

export OSXCROSS_SHA=ea17212e41970b9f602fb30898b5a4013a1fb7af
export CCTOOLS_SHA=6e31355ca5babc708681bd906eaaef86c3ac93be
export LIBTAPI_SHA=640b4623929c923c0468143ff2a363a48665fa54
export XAR_SHA=5fa4675419cfec60ac19a9c7f7c2d0e7c831a497
export PBZX_SHA=2a4d7c3300c826d918def713a24d25c237c8ed53
export APPLE_LLVM_URL=https://github.com/apple/llvm-project/archive/refs/heads/stable/20250402.zip
export APPLE_LLVM_SHA256=b8e87f026e19259e6eac347746661e11592e0ff8bcdb657e177800223d7438ce

export CROSSTOOL_NG_SHA=620b909cd0713f68084378b63cf61b5232757b90
export CT_NG_CONFIGS_SHA=3089a8522a284b4c34a57a051a56c5a81084fbf6

export DASH_VERSION=0.5.12
export DASH_URL=http://deb.debian.org/debian/pool/main/d/dash/dash_${DASH_VERSION}.orig.tar.gz

export TOYBOX_VERSION=0.8.12
export TOYBOX_URL=https://landley.net/toybox/downloads/toybox-${TOYBOX_VERSION}.tar.gz
export TOYBOX_SHA256=ad88a921133ae2231d9f2df875ec0bd42af4429145caea7d7db9e02208a6fd2e

export RCODESIGN_VERSION=0.29.0
export RCODESIGN_PKG_URL_aarch64=https://github.com/indygreg/apple-platform-rs/releases/download/apple-codesign/${RCODESIGN_VERSION}/apple-codesign-${RCODESIGN_VERSION}-aarch64-unknown-linux-musl.tar.gz
export RCODESIGN_PKG_SHA256_aarch64=4af92c87ddf52f5f2d1258a3b4e56c7dcb8f1b2468df744976c5f139e031961f
export RCODESIGN_PKG_URL_x86_64=https://github.com/indygreg/apple-platform-rs/releases/download/apple-codesign/${RCODESIGN_VERSION}/apple-codesign-${RCODESIGN_VERSION}-x86_64-unknown-linux-musl.tar.gz
export RCODESIGN_PKG_SHA256_x86_64=dbe85cedd8ee4217b64e9a0e4c2aef92ab8bcaaa41f20bde99781ff02e600002

if command -v nproc >/dev/null 2>&1; then
    export JOBS="$(nproc)"
elif command -v getconf >/dev/null 2>&1; then
    export JOBS="$(getconf _NPROCESSORS_ONLN)"
else
    export JOBS=4
fi
