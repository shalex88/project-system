#!/bin/bash

# Get the directory where this script is sourced from
TOOLCHAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Export the toolchain file path
export CMAKE_TOOLCHAIN_FILE="/mnt/bsp/bsp/sdk-orin/share/buildroot/toolchainfile.cmake"
# export CROSS_COMPILE="/mnt/bsp/bsp/sdk-orin/bin/aarch64-buildroot-linux-gnu-"

