#!/bin/bash
set -x -e
cd $(dirname $0)
source config.sh

docker run \
    --rm \
    -it \
    -v $PWD:/w \
    -w /w \
    debian:sid \
    ./entrypoint.sh
docker image rm $dockertag || true

docker import $target $dockertag