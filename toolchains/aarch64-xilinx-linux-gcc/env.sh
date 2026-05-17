#!/bin/bash

TOOLCHAIN_ENV="/home/shalex/dev/bsp/sdk-mpsoc-honister/environment-setup-cortexa72-cortexa53-xilinx-linux"
if [ ! -r "${TOOLCHAIN_ENV}" ]; then
    echo "Error: TOOLCHAIN_ENV not found at ${TOOLCHAIN_ENV}" >&2
    return 1
fi

source "${TOOLCHAIN_ENV}"
