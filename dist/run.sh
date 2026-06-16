#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

FLAVOR="${1}"
if [[ "${1:-}" == "$FLAVOR" ]]; then
    shift
fi

./build/fetch.sh "$FLAVOR"

docker build \
    -f "build/Dockerfile.${FLAVOR}" \
    --target artifact \
    --output type=local,dest=dist \
    . "$@"
