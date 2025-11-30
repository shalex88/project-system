set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# vcpkg ports as static libs
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CRT_LINKAGE dynamic)

# Rely on environment-setup for compilers/sysroot
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "")
set(VCPKG_ENV_PASSTHROUGH "CC;CXX;AR;LD;STRIP;AS;RANLIB;PATH;SDKTARGETSYSROOT")

# Ensure PIC for all vcpkg-built static libs (Abseil, RE2, etc.)
set(VCPKG_C_FLAGS "-fPIC")
set(VCPKG_CXX_FLAGS "-fPIC")
