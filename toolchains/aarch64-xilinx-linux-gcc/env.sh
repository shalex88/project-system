#!/bin/bash

TOOLCHAIN="/home/shalex/dev/bsp/sdk-mpsoc-honister/environment-setup-cortexa72-cortexa53-xilinx-linux"
if [ ! -r "${TOOLCHAIN}" ]; then
    echo "Error: Toolchain not found at ${TOOLCHAIN}" >&2
    return 1
fi

source "${TOOLCHAIN}"