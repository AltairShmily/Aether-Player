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

find_path(MPV_INCLUDE_DIR
    NAMES player.h
    HINTS ${PC_MPV_INCLUDE_DIRS}
    PATH_SUFFIXES mpv
)

find_library(MPV_LIBRARY
    NAMES mpv
    HINTS ${PC_MPV_LIBRARY_DIRS}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MPV
    REQUIRED_VARS MPV_LIBRARY MPV_INCLUDE_DIR
)

mark_as_advanced(MPV_INCLUDE_DIR MPV_LIBRARY)
