#!/bin/bash

TOOLCHAIN_ENV="/home/shalex/dev/bsp/sdk-mpsoc-honister/environment-setup-cortexa72-cortexa53-xilinx-linux"
if [ ! -r "${TOOLCHAIN_ENV}" ]; then
    echo "Error: TOOLCHAIN_ENV not found at ${TOOLCHAIN_ENV}" >&2
    return 1
fi

source "${TOOLCHAIN_ENV}"
export VCPKG_OVERLAY_TRIPLETS="/mnt/bsp/projects/project-system/toolchains/aarch64-xilinx-linux-gcc/"
export VCPKG_TARGET_TRIPLET="arm64-xilinx-linux"
export VCPKG_CHAINLOAD_TOOLCHAIN_FILE="${OE_CMAKE_TOOLCHAIN_FILE}"
export VCPKG_FORCE_SYSTEM_BINARIES=1