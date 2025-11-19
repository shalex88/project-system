#!/bin/bash

# Get the directory where this script is sourced from
TOOLCHAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're already inside Docker by looking for /.dockerenv
if [ -f "/.dockerenv" ]; then
    echo "Running inside Docker container"
else
    echo "Running on host - will use Docker for cross-compilation"
    # When on host, we'll use Docker to run the build
    # The build.sh script will detect this and invoke Docker
    export USE_DOCKER_BUILD=1
    export DOCKER_TOOLCHAIN_DIR="$TOOLCHAIN_DIR"
fi
