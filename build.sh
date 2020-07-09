#!/usr/bin/env sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

if [ -f $SCRIPT_DIR/.env ]; then
    . $SCRIPT_DIR/.env
    cat $SCRIPT_DIR/.env
fi

# ref: https://blog.kkty.jp/entry/2019/06/16/214951
tar -czh . | docker build \
        -t ${IMAGE_TAG:-jupyter_datascience_spark} \
        --build-arg BASE_IMAGE=${BASE_IMAGE:-adoptopenjdk:8-jre-hotspot-bionic} \
        --build-arg USER_UID=${USER_UID:-1000} \
        --build-arg PASSWD=${PASSWD:-password} \
        -
