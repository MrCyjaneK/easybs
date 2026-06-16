#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

export STAGING="$EASYBS_ROOT/build/staging/clang21-aarch64-linux-gnu"
export ARTIFACT_NAME=clang21-aarch64-linux-gnu
export TARGET_TRIPLE=aarch64-linux-gnu
export TARGET_CPU=aarch64
export LLVM_TARGET=AArch64
export ELF_ARCH=aarch64
export TARGET_BUILD=aarch64-pc-linux-gnu
export CLANG_VERSION=21
