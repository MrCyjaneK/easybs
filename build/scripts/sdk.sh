#!/bin/bash
set -euxo pipefail

source /w/build/config.clang21-aarch64-apple-darwin.sh

XIP="$1"
cd "$SRC/osxcross"

sed -i.bak "s|\$TARGET_DIR/bin/||g" tools/gen_sdk_package_pbzx.sh
sed -i.bak "s|\$TARGET_DIR/SDK/tools/bin/||g" tools/gen_sdk_package_pbzx.sh

bash -x ./tools/gen_sdk_package_pbzx.sh "$XIP"

mkdir -p "$PREFIX/share/xcode-sdk" "$PREFIX/SDK"
mv ./*.sdk.tar.xz "$PREFIX/share/xcode-sdk/"
tar -xf "$PREFIX/share/xcode-sdk/MacOSX${SDK_VERSION}.sdk.tar.xz" -C "$PREFIX/SDK"

rm -f "$XIP"
