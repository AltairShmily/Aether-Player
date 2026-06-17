cmake_minimum_required(VERSION 3.20)
project(aether_engine VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ── Find MPV ──
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
find_package(MPV REQUIRED)

# ── Find threads ──
find_package(Threads REQUIRED)

# ── Library sources ──
set(ENGINE_SOURCES
    src/core/playback_engine.cpp
    src/ffi/flutter_bridge.cpp
)

# ── Shared library (for Dart FFI) ──
add_library(aether_engine SHARED ${ENGINE_SOURCES})

target_include_directories(aether_engine PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${MPV_INCLUDE_DIR}
)

target_link_libraries(aether_engine PRIVATE
    ${MPV_LIBRARY}
    Threads::Threads
)

# ── Symbol visibility: only export flutter_bridge symbols ──
set_target_properties(aether_engine PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# ── Install ──
install(TARGETS aether_engine
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
