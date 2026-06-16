#!/bin/bash
set -euxo pipefail

source /w/build/scripts/toybox-applets.sh

: "${STAGING:?STAGING must be set by caller}"

BIN="$STAGING/bin"

[[ -f "$BIN/toybox" ]] || { echo "toybox binary missing at $BIN/toybox"; exit 1; }

for applet in "${TOYBOX_APPLETS[@]}"; do
    [[ -e "$BIN/$applet" ]] || ln -sf toybox "$BIN/$applet"
done
