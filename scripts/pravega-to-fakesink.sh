#!/usr/bin/env bash

#
# Copyright (c) Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

set -ex
ROOT_DIR=$(readlink -f $(dirname $0)/..)
LOG_FILE="/tmp/$(basename "${0}" .sh).log"
pushd ${ROOT_DIR}/gst-plugin-pravega
cargo build
ls -lh ${ROOT_DIR}/target/debug/*.so
export GST_PLUGIN_PATH=${ROOT_DIR}/target/debug:${GST_PLUGIN_PATH}
export GST_DEBUG="pravegasrc:TRACE"
export PRAVEGA_VIDEO_LOG=debug
export RUST_BACKTRACE=1
PRAVEGA_CONTROLLER_URI=${PRAVEGA_CONTROLLER_URI:-127.0.0.1:9090}
PRAVEGA_SCOPE=${PRAVEGA_SCOPE:-examples}
PRAVEGA_STREAM=${PRAVEGA_STREAM:-test1}
ALLOW_CREATE_SCOPE=${ALLOW_CREATE_SCOPE:-true}
export GST_DEBUG_DUMP_DOT_DIR="/tmp/gst-dot/$(basename "${0}" .sh)"
mkdir -p ${GST_DEBUG_DUMP_DOT_DIR}

gst-launch-1.0 \
-v \
pravegasrc \
  allow-create-scope=${ALLOW_CREATE_SCOPE} \
  controller=${PRAVEGA_CONTROLLER_URI} \
  keycloak-file=\"${KEYCLOAK_SERVICE_ACCOUNT_FILE}\" \
  stream=${PRAVEGA_SCOPE}/${PRAVEGA_STREAM} \
  $* \
! identity silent=false \
! fakesink sync=false \
|& tee ${LOG_FILE}
