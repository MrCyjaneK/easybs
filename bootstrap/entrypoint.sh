#!/bin/bash
set -x -e
cd $(dirname $0)

apt update
apt upgrade -y

apt install -y mmdebstrap

./build.sh