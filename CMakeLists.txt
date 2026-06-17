# ═══════════════════════════════════════════════════
#  Aether Player — CMake + Ninja 构建系统
#
#  用法:
#    cmake -B build -G Ninja
#    cmake --build build
#    cmake --build build --target package-linux
# ═══════════════════════════════════════════════════

cmake_minimum_required(VERSION 3.20)
project(aether-player VERSION 1.0.0 LANGUAGES NONE)

# ── 选项 ─────────────────────────────────────────────
option(BUILD_SERVER   "Build Go backend"        ON)
option(BUILD_FLUTTER  "Build Flutter client"     ON)
option(BUILD_ENGINE   "Build C++ media engine"   OFF)
option(PACKAGE_APPIMAGE "Package as AppImage"    OFF)
option(PACKAGE_DEB    "Package as .deb"          OFF)

# ── 路径 ─────────────────────────────────────────────
set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
set(SERVER_DIR   ${PROJECT_ROOT}/server)
set(APP_DIR      ${PROJECT_ROOT}/app)
set(ENGINE_DIR   ${PROJECT_ROOT}/engine)
set(OUT_DIR      ${PROJECT_ROOT}/build/output)

# ── 平台检测 ─────────────────────────────────────────
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(HOST_OS "linux")
    set(SERVER_BIN "aether-server")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(HOST_OS "windows")
    set(SERVER_BIN "aether-server.exe")
else()
    message(FATAL_ERROR "Unsupported host OS: ${CMAKE_HOST_SYSTEM_NAME}")
endif()

# ════════════════════════════════════════════════════
#  Go 后端
# ════════════════════════════════════════════════════
if(BUILD_SERVER)
    # 查找 Go
    find_program(GO_EXECUTABLE go REQUIRED)
    message(STATUS "Found Go: ${GO_EXECUTABLE}")

    # 输出路径
    set(SERVER_OUTPUT ${OUT_DIR}/${SERVER_BIN})

    # 构建命令
    add_custom_command(
        OUTPUT ${SERVER_OUTPUT}
        COMMAND ${CMAKE_COMMAND} -E env
            CGO_ENABLED=0
            GOOS=${HOST_OS}
            GOARCH=amd64
            ${GO_EXECUTABLE} build
            -ldflags=-s\ -w
            -o ${SERVER_OUTPUT}
            ./cmd/api/
        WORKING_DIRECTORY ${SERVER_DIR}
        COMMENT "Building Go backend..."
        DEPENDS ${SERVER_DIR}/cmd/api/main.go
    )

    add_custom_target(server ALL DEPENDS ${SERVER_OUTPUT})
endif()

# ════════════════════════════════════════════════════
#  C++ 媒体引擎
# ════════════════════════════════════════════════════
if(BUILD_ENGINE)
    add_custom_target(engine
        COMMAND ${CMAKE_COMMAND} -B ${OUT_DIR}/engine
            -S ${ENGINE_DIR}
            -G Ninja
            -DCMAKE_BUILD_TYPE=Release
        COMMAND ${CMAKE_COMMAND} --build ${OUT_DIR}/engine
        COMMENT "Building C++ media engine..."
    )
endif()

# ════════════════════════════════════════════════════
#  Flutter 客户端
# ════════════════════════════════════════════════════
if(BUILD_FLUTTER)
    # 查找 Flutter
    find_program(FLUTTER_EXECUTABLE flutter REQUIRED)
    message(STATUS "Found Flutter: ${FLUTTER_EXECUTABLE}")

    # Flutter 子命令封装
    set(FLUTTER_CMD ${FLUTTER_EXECUTABLE} --suppress-analytics)

    # 初始化平台目录（如果不存在）
    if(NOT EXISTS ${APP_DIR}/linux/CMakeLists.txt)
        add_custom_command(
            OUTPUT ${APP_DIR}/linux/CMakeLists.txt
            COMMAND ${FLUTTER_CMD} create --platforms=${HOST_OS} .
            WORKING_DIRECTORY ${APP_DIR}
            COMMENT "Initializing Flutter platform..."
        )
        add_custom_target(flutter-init DEPENDS ${APP_DIR}/linux/CMakeLists.txt)
    endif()

    # pub get
    add_custom_target(flutter-deps
        COMMAND ${FLUTTER_CMD} pub get
        WORKING_DIRECTORY ${APP_DIR}
        COMMENT "Installing Flutter dependencies..."
    )

    # i18n 生成
    add_custom_target(flutter-i18n
        COMMAND ${FLUTTER_EXECUTABLE} --suppress-analytics run slang
        WORKING_DIRECTORY ${APP_DIR}
        COMMENT "Generating i18n..."
        DEPENDS flutter-deps
    )

    # Flutter 构建
    if(HOST_OS STREQUAL "linux")
        set(FLUTTER_BUILD_CMD ${FLUTTER_CMD} build linux --release)
        set(FLUTTER_BUNDLE_DIR ${APP_DIR}/build/linux/x64/release/bundle)
    elseif(HOST_OS STREQUAL "windows")
        set(FLUTTER_BUILD_CMD ${FLUTTER_CMD} build windows --release)
        set(FLUTTER_BUNDLE_DIR ${APP_DIR}/build/windows/x64/runner/Release)
    endif()

    add_custom_target(flutter-build
        COMMAND ${FLUTTER_BUILD_CMD}
        WORKING_DIRECTORY ${APP_DIR}
        COMMENT "Building Flutter ${HOST_OS} release..."
        DEPENDS flutter-i18n
    )

    # 合并：将 Go 二进制复制到 Flutter bundle
    if(BUILD_SERVER)
        add_custom_command(
            TARGET flutter-build POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                ${SERVER_OUTPUT}
                ${FLUTTER_BUNDLE_DIR}/${SERVER_BIN}
            COMMAND ${CMAKE_COMMAND} -E chmod +x
                ${FLUTTER_BUNDLE_DIR}/${SERVER_BIN}
            COMMENT "Bundling Go server into Flutter app..."
        )
    endif()
endif()

# ════════════════════════════════════════════════════
#  打包 — AppImage
# ════════════════════════════════════════════════════
if(PACKAGE_APPIMAGE AND HOST_OS STREQUAL "linux")
    set(APPIMAGE_DIR ${OUT_DIR}/appimage)

    add_custom_target(package-appimage
        COMMAND ${CMAKE_COMMAND} -E make_directory ${APPIMAGE_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${FLUTTER_BUNDLE_DIR} ${APPIMAGE_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy
            ${PROJECT_ROOT}/packaging/linux/aether.desktop ${APPIMAGE_DIR}/
        COMMAND ${CMAKE_COMMAND} -E copy
            ${PROJECT_ROOT}/packaging/linux/AppRun ${APPIMAGE_DIR}/
        COMMAND ${CMAKE_COMMAND} -E chmod +x
            ${APPIMAGE_DIR}/AppRun
            ${APPIMAGE_DIR}/aether-server
        COMMENT "Packaging AppImage..."
        DEPENDS flutter-build
    )
endif()

# ════════════════════════════════════════════════════
#  打包 — .deb
# ════════════════════════════════════════════════════
if(PACKAGE_DEB AND HOST_OS STREQUAL "linux")
    set(DEB_NAME "aether_${PROJECT_VERSION}_amd64")
    set(DEB_DIR ${OUT_DIR}/deb/${DEB_NAME})

    add_custom_target(package-deb
        # 创建目录结构
        COMMAND ${CMAKE_COMMAND} -E make_directory ${DEB_DIR}/DEBIAN
        COMMAND ${CMAKE_COMMAND} -E make_directory ${DEB_DIR}/opt/aether
        COMMAND ${CMAKE_COMMAND} -E make_directory ${DEB_DIR}/usr/share/applications
        COMMAND ${CMAKE_COMMAND} -E make_directory ${DEB_DIR}/usr/local/bin
        # 复制文件
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${FLUTTER_BUNDLE_DIR} ${DEB_DIR}/opt/aether
        COMMAND ${CMAKE_COMMAND} -E copy
            ${PROJECT_ROOT}/packaging/linux/aether.desktop
            ${DEB_DIR}/usr/share/applications/
        # 符号链接
        COMMAND ${CMAKE_COMMAND} -E create_symlink
            /opt/aether/aether ${DEB_DIR}/usr/local/bin/aether
        COMMAND ${CMAKE_COMMAND} -E create_symlink
            /opt/aether/aether-server ${DEB_DIR}/usr/local/bin/aether-server
        # 写入 control 文件
        COMMAND ${CMAKE_COMMAND} -E echo
            "Package: aether\nVersion: ${PROJECT_VERSION}\nSection: video\nPriority: optional\nArchitecture: amd64\nDepends: libmpv2 | libmpv1, libgtk-3-0\nMaintainer: AltairShmily\nDescription: Aether Player — Emby Media Client"
            > ${DEB_DIR}/DEBIAN/control
        # 构建 .deb
        COMMAND dpkg-deb --build ${DEB_DIR}
        COMMENT "Packaging .deb..."
        DEPENDS flutter-build
    )
endif()

# ════════════════════════════════════════════════════
#  便捷目标
# ════════════════════════════════════════════════════

# 全量构建
add_custom_target(all-in-one
    COMMENT "Building everything..."
)
if(BUILD_SERVER)
    add_dependencies(all-in-one server)
endif()
if(BUILD_FLUTTER)
    add_dependencies(all-in-one flutter-build)
endif()

# 打包（取决于选项）
add_custom_target(package COMMENT "Packaging...")
if(PACKAGE_APPIMAGE AND HOST_OS STREQUAL "linux")
    add_dependencies(package package-appimage)
endif()
if(PACKAGE_DEB AND HOST_OS STREQUAL "linux")
    add_dependencies(package package-deb)
endif()

# 清理
add_custom_target(distclean
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${PROJECT_ROOT}/build
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${APP_DIR}/build
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${OUT_DIR}
    COMMENT "Cleaning all build artifacts..."
)
