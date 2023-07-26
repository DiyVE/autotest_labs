#!/bin/bash

set -e

# Training info
export LABBOARD="beagleplay"
export SESSION_NAME="embedded-linux-beagleplay"
export LAB_URL="https://bootlin.com/doc/training/embedded-linux/embedded-linux-labs.tar.xz"
export LAB_KERNEL_VERSION=6.4

export LAB_DIR=$PWD/out/$SESSION_NAME-labs

cd lab-scripts

# Test sequence
./setup.sh
./sysdev-toolchain.sh
./sysdev-u-boot-beagply.sh
./sysdev-kernel-fetch-sources.sh
./sysdev-kernel-cross-compiling.sh