#!/bin/bash
set -x -e
cd $(dirname $0)

source config.sh

if [[ ! -d dist/$ver ]];
then
    mkdir -p dist/$ver
fi

mmdebstrap \
    --aptopt='Acquire::Check-Valid-Until "false"' \
    --customize-hook='echo easybs > "$1/etc/hostname"' \
    --customize-hook='echo "127.0.0.1 localhost easybs" > "$1/etc/hosts"' \
    --customize-hook='chroot "$1" git config --global user.name easybs' \
    --customize-hook='chroot "$1" git config --global user.email easybs@mrcyjanek.net' \
    --include=$PKGS \
    trixie \
    $target \
    $mirror

# ????????
# --customize-hook='rm "$1"/etc/resolv.conf'
# --customize-hook='rm "$1"/etc/hostname'