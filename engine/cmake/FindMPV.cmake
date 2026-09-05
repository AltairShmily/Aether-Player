# FindMPV.cmake
# Finds libmpv development headers and library
#
# Sets:
#   MPV_FOUND
#   MPV_INCLUDE_DIR
#   MPV_LIBRARY

find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(PC_MPV QUIET mpv)
endif()

# 按 mpv/client.h 的相对路径查找，使 MPV_INCLUDE_DIR 落在 /usr/include 这一层。
# 源码使用 #include <mpv/client.h>，而 pkg-config 给出的 -I/usr/include/mpv
# 是给 #include <client.h> 风格用的，直接用会导致头文件路径多一层 mpv/。
# 注意：libmpv 并不安装 player.h（那是 mpv 的内部头），不能用它作为探测目标。
find_path(MPV_INCLUDE_DIR
    NAMES mpv/client.h
    HINTS ${PC_MPV_INCLUDEDIR} ${PC_MPV_INCLUDE_DIRS}
    PATH_SUFFIXES ../
)

find_library(MPV_LIBRARY
    NAMES mpv
    HINTS ${PC_MPV_LIBDIR} ${PC_MPV_LIBRARY_DIRS}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MPV
    REQUIRED_VARS MPV_LIBRARY MPV_INCLUDE_DIR
)

mark_as_advanced(MPV_INCLUDE_DIR MPV_LIBRARY)
