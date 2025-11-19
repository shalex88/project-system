cmake_minimum_required(VERSION 3.16)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# ------------------------------------------------------------------
# SYSROOT (Buildroot sysroot only!)
# ------------------------------------------------------------------
if(NOT CMAKE_SYSROOT)
    if(DEFINED ENV{CMAKE_SYSROOT})
        set(CMAKE_SYSROOT "$ENV{CMAKE_SYSROOT}")
    else()
        message(FATAL_ERROR
            "CMAKE_SYSROOT not set. Use the Buildroot toolchain sysroot, e.g.:\n"
            "  -DCMAKE_SYSROOT=/l4t/toolchain/aarch64--glibc--stable-2022.08-1/aarch64-buildroot-linux-gnu/sysroot"
        )
    endif()
endif()

set(TARGET_SYSROOT $ENV{TARGET_SYSROOT})

# ------------------------------------------------------------------
# Cross compilers
# ------------------------------------------------------------------
set(CROSS_PREFIX "/l4t/toolchain/aarch64--glibc--stable-2022.08-1/bin/aarch64-buildroot-linux-gnu")
set(CMAKE_C_COMPILER  "${CROSS_PREFIX}-gcc")
set(CMAKE_CXX_COMPILER "${CROSS_PREFIX}-g++")

# ------------------------------------------------------------------
# Compiler flags (INIT so vcpkg can extend them)
# ------------------------------------------------------------------
set(CMAKE_C_FLAGS_INIT   "--sysroot=${CMAKE_SYSROOT}")
set(CMAKE_CXX_FLAGS_INIT "--sysroot=${CMAKE_SYSROOT}")

set(CMAKE_EXE_LINKER_FLAGS_INIT
    "-Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu \
     -Wl,-rpath-link,${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu \
     -Wl,-rpath-link,${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu/tegra")
set(CMAKE_SHARED_LINKER_FLAGS_INIT
    "-Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu \
     -Wl,-rpath-link,${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu \
     -Wl,-rpath-link,${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu/tegra")

# ------------------------------------------------------------------
# pkg-config
# ------------------------------------------------------------------
find_program(PKG_CONFIG_EXECUTABLE pkg-config REQUIRED)

set(_pc_target1 "${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig")
set(_pc_target2 "${TARGET_SYSROOT}/usr/lib/pkgconfig")
set(_pc_target3 "${TARGET_SYSROOT}/usr/share/pkgconfig")

# OpenBLAS/OpenMPI subpaths
set(_pc_openblas "${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu/openblas-pthread/pkgconfig")
set(_pc_openmpi  "${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu/openmpi/lib/pkgconfig")
set(_pc_opencoarrays "${TARGET_SYSROOT}/usr/lib/aarch64-linux-gnu/open-coarrays/openmpi/pkgconfig")

# Buildroot toolchain pkg-config files
set(_pc_toolchain "${TOOLCHAIN}/lib/pkgconfig")

set(ENV{PKG_CONFIG_PATH}
    "${_pc_target1}:${_pc_target2}:${_pc_target3}:${_pc_openblas}:${_pc_openmpi}:${_pc_opencoarrays}:${_pc_toolchain}"
)

# ------------------------------------------------------------------
# Prevent CMake from using target executables (gmake, pkg-config, python)
# ------------------------------------------------------------------
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Let vcpkg manage library/include paths

set(VCPKG_TARGET_TRIPLET "arm64-linux-release")