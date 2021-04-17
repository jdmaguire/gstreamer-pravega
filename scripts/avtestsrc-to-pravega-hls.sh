#!/usr/bin/env bash

# Generate audio and video and write to Pravega as an MPEG Transport Stream.

set -ex
ROOT_DIR=$(readlink -f $(dirname $0)/..)
pushd ${ROOT_DIR}/gst-plugin-pravega
cargo build
ls -lh ${ROOT_DIR}/gst-plugin-pravega/target/debug/*.so
export GST_PLUGIN_PATH=${ROOT_DIR}/gst-plugin-pravega/target/debug:${GST_PLUGIN_PATH}
# log level can be INFO, DEBUG, or LOG (verbose)
export GST_DEBUG=pravegasink:DEBUG
export RUST_BACKTRACE=1
export TZ=UTC
STREAM=${STREAM:-hlsav1}
SIZE_SEC=86400
FPS=30
KEY_FRAME_INTERVAL=$((5*$FPS))

gst-launch-1.0 \
-v \
videotestsrc is-live=true do-timestamp=true num-buffers=$(($SIZE_SEC*$FPS)) \
! "video/x-raw,width=640,height=480,framerate=30/1" \
! videoconvert \
! clockoverlay "font-desc=Sans 48px" "time-format=%F %T" shaded-background=true \
! timeoverlay valignment=bottom "font-desc=Sans 48px" shaded-background=true \
! queue \
! x264enc key-int-max=${KEY_FRAME_INTERVAL} tune=zerolatency speed-preset=medium bitrate=500 \
! queue ! mux. \
audiotestsrc is-live=true do-timestamp=true \
             samplesperbuffer=$((44100/$FPS)) num-buffers=$(($SIZE_SEC*$FPS)) \
             wave=ticks volume=0.5 marker-tick-period=5 \
! queue \
! audioconvert \
! "audio/x-raw,rate=44100,channels=2" \
! avenc_aac \
! queue ! mux. \
mpegtsmux name=mux \
! queue \
! pravegasink stream=examples/${STREAM} sync=false
