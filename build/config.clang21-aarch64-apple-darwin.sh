#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

export STAGING="$EASYBS_ROOT/build/staging/clang21-aarch64-apple-darwin"
export ARTIFACT_NAME=clang21-aarch64-apple-darwin
export SDK_VERSION=26.1
export OSX_MIN=13.0
export CLANG_VERSION=21
export ENABLE_ARCHS=arm64
