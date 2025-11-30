#!/bin/bash

# Get the directory where this script is sourced from
TOOLCHAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're already inside Docker by looking for /.dockerenv
if [ ! -f "/.dockerenv" ]; then
    export USE_DOCKER_BUILD=1
    export DOCKER_TOOLCHAIN_DIR="$TOOLCHAIN_DIR"
fi

export VCPKG_TARGET_TRIPLET="arm64-linux-release"
export VCPKG_FORCE_SYSTEM_BINARIES=1
