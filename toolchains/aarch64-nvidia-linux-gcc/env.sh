#!/bin/bash

TOOLCHAIN_ENV="/home/shalex/dev/bsp/sdk-orin-scarthgap/environment-setup-armv8a-oe4t-linux"
if [ ! -r "${TOOLCHAIN_ENV}" ]; then
    echo "Error: TOOLCHAIN_ENV not found at ${TOOLCHAIN_ENV}" >&2
    return 1
fi

source "${TOOLCHAIN_ENV}"
