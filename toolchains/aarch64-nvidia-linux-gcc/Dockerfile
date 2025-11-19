# Stage 1: Extract archives and clean up
FROM nvcr.io/nvidia/jetpack-linux-aarch64-crosscompile-x86:6.1 AS extractor

WORKDIR /l4t

RUN mkdir toolchain \
 && tar -C toolchain -xf toolchain.tar.bz2 \
 && cat targetfs.tbz2.* > targetfs.tbz2 \
 && tar -I lbzip2 -xf targetfs.tbz2

# Stage 2: Final image with extracted files and build tools
FROM nvcr.io/nvidia/jetpack-linux-aarch64-crosscompile-x86:6.1

WORKDIR /l4t

# Copy extracted files from the extractor stage
COPY --from=extractor /l4t/toolchain ./toolchain
COPY --from=extractor /l4t/targetfs ./targetfs

RUN rm -f toolchain.tar.bz2 targetfs.tbz2*

# Set environment variable for CMake toolchain file (wrapper)
COPY orin-toolchain.cmake /l4t/orin-toolchain.cmake

# Set environment variables for CMake cross-compilation
ENV CMAKE_TOOLCHAIN_FILE=/l4t/orin-toolchain.cmake
ENV TOOLCHAIN=/l4t/toolchain/aarch64--glibc--stable-2022.08-1
ENV CMAKE_SYSROOT=/l4t/toolchain/aarch64--glibc--stable-2022.08-1/aarch64-buildroot-linux-gnu/sysroot
ENV TARGET_SYSROOT=/l4t/targetfs

# Install tools required for vcpkg bootstrap and building
RUN apt-get update && apt-get install -y \
    curl \
    zip \
    unzip \
    tar \
    git \
    pkg-config \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Fix .pc files in target rootfs to use ${pc_sysrootdir}
RUN find /l4t/targetfs -name "*.pc" -type f -exec sed -i \
    -e 's|^prefix=/usr|prefix=/l4t/targetfs/usr|g' \
    {} \;

# Also fix toolchain .pc files
RUN find /l4t/toolchain -name "*.pc" -type f -exec sed -i \
    -e 's|^prefix=/usr|prefix=/l4t/toolchain/aarch64--glibc--stable-2022.08-1/usr|g' \
    {} \;

# Create user with same UID/GID as host user to avoid permission issues
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=developer

RUN groupadd -g ${GROUP_ID} ${USERNAME} || true \
 && useradd -l -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ${USERNAME}

USER ${USERNAME}
WORKDIR /workspace