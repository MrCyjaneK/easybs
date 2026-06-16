#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

export STAGING="$EASYBS_ROOT/build/staging/clang21-x86_64-linux-gnu"
export ARTIFACT_NAME=clang21-x86_64-linux-gnu
export TARGET_TRIPLE=x86_64-linux-gnu
export TARGET_CPU=x86_64
export LLVM_TARGET=X86
export ELF_ARCH=x86-64
export TARGET_BUILD=x86_64-pc-linux-gnu
export CLANG_VERSION=21
