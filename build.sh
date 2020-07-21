#!/usr/bin/env sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

if [ -f $SCRIPT_DIR/.env ]; then
    . $SCRIPT_DIR/.env
    cat $SCRIPT_DIR/.env
fi

# ref: https://blog.kkty.jp/entry/2019/06/16/214951
tar -czh . | docker build \
        -t ${IMAGE_TAG:-jupyter_datascience_spark24} \
        --build-arg BASE_IMAGE=${BASE_IMAGE:-adoptopenjdk:8u252-b09-jre-hotspot-bionic} \
        -
