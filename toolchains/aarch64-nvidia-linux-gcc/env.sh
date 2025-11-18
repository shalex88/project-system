#!/bin/bash

# Get the directory where this script is sourced from
TOOLCHAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're already inside Docker by looking for /.dockerenv
if [ -f "/.dockerenv" ]; then
    echo "Running inside Docker container"
    # Export the toolchain file path (inside container)
    export CMAKE_TOOLCHAIN_FILE="/l4t/toolchain/aarch64--glibc--stable-2022.08-1/share/buildroot/toolchainfile.cmake"
    
    # Set PKG_CONFIG paths to find GStreamer in the target filesystem
    # The sysroot should point to the targetfs root
    export PKG_CONFIG_SYSROOT_DIR="/l4t/targetfs"
    export PKG_CONFIG_PATH="/l4t/targetfs/usr/lib/aarch64-linux-gnu/pkgconfig:/l4t/targetfs/usr/share/pkgconfig"
    export PKG_CONFIG_LIBDIR="/l4t/targetfs/usr/lib/aarch64-linux-gnu/pkgconfig:/l4t/targetfs/usr/share/pkgconfig"
else
    echo "Running on host - will use Docker for cross-compilation"
    # When on host, we'll use Docker to run the build
    # The build.sh script will detect this and invoke Docker
    export USE_DOCKER_BUILD=1
    export DOCKER_TOOLCHAIN_DIR="$TOOLCHAIN_DIR"
fi
