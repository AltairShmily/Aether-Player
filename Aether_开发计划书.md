# Aether — 开发计划书

## 一、项目概述

Aether 是一款基于 Emby 生态的跨平台媒体播放器客户端，支持 **Windows / Android / macOS / Linux** 四端。

项目以学习和提升编程能力为核心目的，采用三种语言协作开发：

| 层级 | 语言 | 职责 |
|------|------|------|
| 前端客户端 | **Dart / Flutter** | UI、交互、状态管理、跨平台适配 |
| 后端网关 | **Go** | API 代理、认证、媒体元数据、转码调度 |
| 媒体引擎 | **C++** | 播放核心、FFmpeg/libmpv 封装、硬件加速、FFI 桥接 |

---

## 二、架构设计

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter Client (Dart)                   │
│              Windows / Android / macOS / Linux           │
│  ┌────────────┬────────────────┬──────────────────────┐  │
│  │ 媒体库 UI  │ 播放器引擎     │ 下载/缓存管理        │  │
│  └────────────┴───────┬────────┴──────────────────────┘  │
│                       │ HTTP / gRPC                      │
├───────────────────────┼──────────────────────────────────┤
│              Go Backend (API Gateway)                    │
│  ┌────────────┬────────────────┬──────────────────────┐  │
│  │ 用户认证   │ 媒体元数据     │ 转码调度 / 流代理    │  │
│  └────────────┴───────┬────────┴──────────────────────┘  │
│                       │ CGo / gRPC                       │
├───────────────────────┼──────────────────────────────────┤
│           C++ Media Engine (核心处理)                    │
│  ┌────────────┬────────────────┬──────────────────────┐  │
│  │ FFmpeg     │ 硬件解码       │ 音视频解码/渲染      │  │
│  │ libmpv     │ 转码流水线     │ Flutter FFI 桥接     │  │
│  └────────────┴────────────────┴──────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 三、技术选型

### 前端（Flutter）

| 技术 | 用途 |
|------|------|
| Flutter 3.x | 跨平台 UI 框架 |
| Riverpod | 状态管理 |
| Dio | HTTP 客户端 |
| media_kit | 初期播放器（底层 libmpv） |
| shared_preferences | 本地持久化 |
| Google Fonts | 自定义字体 |

### 后端（Go）

| 技术 | 用途 |
|------|------|
| net/http (标准库) | HTTP 服务器 |
| gorilla/mux | 路由 |
| golang-jwt | JWT 认证 |
| slog | 结构化日志 |
| gRPC | 与 C++ 引擎通信（后期） |

### 媒体引擎（C++）

| 技术 | 用途 |
|------|------|
| FFmpeg | 解封装、编解码 |
| libmpv | 播放器核心 |
| CMake | 构建系统 |
| vcpkg | 包管理（可选） |
| nlohmann-json | JSON 解析 |
| spdlog | 日志 |
| gRPC C++ | 服务端转码（后期） |

---

## 四、仓库结构

```
Aether/
├── .github/
│   └── workflows/
│       └── build.yml              # CI/CD（Windows/macOS/Android 构建）
├── .vscode/
│   ├── settings.json
│   └── extensions.json
├── scripts/
│   ├── setup_fedora.sh            # Fedora 一键装环境
│   ├── build_engine_linux.sh      # Linux C++ 构建脚本
│   └── build_android.sh           # Android 打包脚本
├── app/                           # Flutter 客户端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── theme/
│   │   ├── models/
│   │   ├── services/
│   │   ├── providers/
│   │   └── screens/
│   ├── android/
│   ├── macos/
│   ├── windows/
│   └── pubspec.yaml
├── server/                        # Go 后端
│   ├── cmd/api/main.go
│   ├── internal/
│   │   ├── emby/client.go
│   │   ├── handler/auth.go
│   │   └── middleware/middleware.go
│   ├── model.go
│   └── go.mod
├── engine/                        # C++ 媒体引擎
│   ├── CMakeLists.txt
│   ├── vcpkg.json
│   ├── src/
│   │   ├── core/
│   │   ├── emby/
│   │   ├── ffi/
│   │   └── grpc/
│   ├── cmake/
│   └── tests/
├── Makefile
├── .gitignore
└── README.md
```

---

## 五、开发环境要求

### 操作系统

| 平台 | 角色 |
|------|------|
| **Fedora 43 Workstation** | 主力开发机（日常编码、调试、测试） |
| Windows | CI/CD 构建（GitHub Actions） |
| macOS | CI/CD 构建（GitHub Actions） |

### 必装工具

| 工具 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | 3.41+ | 客户端开发 |
| Go | 1.22+ | 后端开发 |
| GCC / Clang | 最新 | C++ 编译 |
| CMake | 3.20+ | C++ 构建 |
| Ninja | 最新 | C++ 构建（推荐） |
| Android SDK | 36 | Android 构建 |
| Android NDK | 26+ | Android C++ 交叉编译 |
| libmpv-devel | — | 播放器核心 |
| ffmpeg-devel | 7.x | 音视频编解码 |
| vcpkg | 最新 | C++ 包管理（可选） |
| Git | — | 版本控制 |

### Fedora 43 环境一键安装

```bash
chmod +x scripts/setup_fedora.sh
./scripts/setup_fedora.sh
```

### 验证命令

```bash
flutter doctor       # 检查 Flutter 全链路
go version           # 检查 Go
cmake --version      # 检查 CMake
pkg-config --modversion mpv        # 检查 libmpv
pkg-config --modversion libavcodec # 检查 FFmpeg
```

---

## 六、分阶段开发计划

### Step 0：环境搭建 ✅

**目标：** 三语言工具链就绪，验证最小可运行程序。

| 子任务 | 产出 |
|--------|------|
| 安装 Flutter SDK + Android SDK + Go + C++ 工具链 | `flutter doctor` 全绿 |
| 创建 monorepo 根目录 + Git 初始化 | Aether/ 仓库骨架 |
| `flutter create` 初始化客户端 | 空白 Flutter 应用可运行 |
| Go 最小 HTTP 服务 | `localhost:8080/api/health` 返回 JSON |
| C++ 最小 CMake 项目 | 可编译、可测试 |
| 根目录 Makefile | `make setup` 一键检查环境 |

---

### Step 1：Emby 登录与服务连接 ✅

**目标：** 用户能输入 Emby 服务器地址并完成登录认证。

| 子任务 | 层级 | 说明 |
|--------|------|------|
| Emby API 客户端 | Go | 封装 `TestConnection` + `Authenticate` |
| JWT 签发与验证 | Go | 登录成功后签发 7 天有效期 JWT |
| 认证中间件 | Go | `Authorization: Bearer <token>` 校验 |
| API 路由 | Go | `POST /api/auth/connect`、`POST /api/auth/login`、`GET /api/auth/validate` |
| 登录页 UI | Flutter | 服务器地址输入 → 连接测试 → 用户名/密码 → 登录 |
| 会话持久化 | Flutter | JWT + 服务器信息存入 SharedPreferences |
| 自动恢复登录 | Flutter | 启动时读取本地 token，调用 validate 接口 |
| 玻璃态卡片 UI | Flutter | 深色主题、渐变按钮、连接状态动画 |

**关键 API：**

```
POST /api/auth/connect     { server_url }         → { server_name, version, server_id }
POST /api/auth/login       { server_url, username, password } → { token, user, server }
GET  /api/auth/validate    Header: Bearer <token>  → { user_id, user_name, server_url }
```

**Flutter 文件清单：**

```
lib/
├── main.dart
├── app.dart                      # 路由：登录 vs 首页
├── theme/app_theme.dart          # 主题色板
├── models/auth_models.dart       # 数据模型
├── services/api_client.dart      # Dio HTTP 客户端
├── services/storage_service.dart  # SharedPreferences 封装
├── providers/auth_provider.dart  # Riverpod 状态管理
└── screens/
    ├── login_screen.dart         # 登录页
    └── home_screen.dart          # 登录成功首页（占位）
```

**Go 文件清单：**

```
server/
├── cmd/api/main.go               # 入口 + 路由注册
├── model.go                      # 共享模型 + JWT Claims
├── go.mod
└── internal/
    ├── emby/client.go            # Emby API 客户端
    ├── handler/auth.go           # HTTP 处理器
    └── middleware/middleware.go   # CORS / 日志 / JWT 中间件
```

**验证方式：**

```
1. 启动 Go 后端：cd server && go run ./cmd/api/
2. 启动 Flutter：cd app && flutter run -d linux
3. 输入 Emby 地址 → 点 Connect → 显示服务器名称
4. 输入账号密码 → 点 Sign In → 跳转 Home 页
5. 关闭应用 → 重新打开 → 自动登录
6. 点退出 → 回到登录页
```

---

### Step 2：媒体库浏览

**目标：** 展示 Emby 媒体库的海报墙，支持分类、搜索、分页加载。

| 子任务 | 层级 | 说明 |
|--------|------|------|
| 媒体库 API 代理 | Go | 代理 `/Users/{id}/Items`，支持分页/排序/筛选 |
| 图片代理 | Go | 代理 `/Items/{id}/Images/{type}`，避免暴露 token |
| 搜索接口 | Go | 代理 Emby 搜索 API |
| 海报墙 UI | Flutter | `GridView` + 缓存图片 + 网格动画 |
| 媒体详情页 | Flutter | 海报、简介、评分、音视频流信息 |
| 分页加载 | Flutter | 滚动到底自动加载下一页 |
| 搜索功能 | Flutter | 搜索栏 + 实时结果 |
| 侧边栏导航 | Flutter | 电影/电视剧/音乐分类切换 |

**关键 API：**

```
GET /api/library/items?page=1&limit=20&type=Movie&sort=DateCreated  → { items, total }
GET /api/library/items/{id}                                         → { item detail }
GET /api/images/{id}/Primary?maxWidth=300                           → image binary
GET /api/search?term=xxx                                            → { results }
```

---

### Step 3：视频播放（集成 media_kit）

**目标：** 点击媒体项进入播放页，支持基础播放控制。

| 子任务 | 层级 | 说明 |
|--------|------|------|
| 流媒体 URL 构造 | Go | 判断 Direct Play / Transcode，返回播放 URL |
| 播放引擎抽象层 | Flutter | `PlayerEngine` 接口（play/pause/seek/轨道切换） |
| media_kit 集成 | Flutter | 基于 libmpv 的播放器实现 |
| 播放页 UI | Flutter | 视频渲染 + 自定义控制栏 + 进度条 |
| 播放控制 | Flutter | 播放/暂停、进度拖拽、倍速、全屏 |
| 音轨/字幕切换 | Flutter | 通过 mpv API 切换 |
| 播放进度上报 | Go + Flutter | 每 10 秒向 Emby 报告进度（续播功能） |
| Emby 认证头注入 | Flutter | 播放 URL 需携带 `api_key` 参数 |

**关键 API：**

```
GET  /api/playback/{id}/info       → { mediaSources, playSessionId }
GET  /api/playback/{id}/stream     → { directPlayURL / transcodeURL }
POST /api/playback/progress        → 上报 { itemId, positionTicks }
POST /api/playback/started         → 开始播放通知
POST /api/playback/stopped         → 停止播放通知
```

**播放器架构：**

```
PlayerPage (UI)
    │
    ▼
PlayerController (Riverpod StateNotifier)
    │  管理状态：播放/暂停/进度/缓冲/轨道
    ▼
PlayerEngine (抽象接口)
    ├── MpvEngine (media_kit，初期使用)
    └── NativeFFmpegEngine (C++ FFI，后期替换)
```

---

### Step 4：C++ 媒体引擎（自研 FFI）

**目标：** 用 C++ 封装 libmpv，通过 FFI 替换 media_kit，深入学习 C++ 工程实践。

| 子任务 | 层级 | 说明 |
|--------|------|------|
| libmpv C++ 封装 | C++ | `PlaybackEngine` 类：open/play/pause/seek/轨道 |
| 事件循环 | C++ | mpv 事件轮询线程，分发状态/进度/错误回调 |
| 媒体信息解析 | C++ | 解析 track-list 获取音视频字幕轨信息 |
| Flutter FFI 导出 | C++ | `extern "C"` 导出函数，供 Dart `dart:ffi` 调用 |
| Dart FFI 绑定 | Flutter | `DynamicLibrary` + 函数签名绑定 |
| 替换 media_kit | Flutter | 用自研引擎替换 MpvEngine |
| 跨平台编译 | CMake | Linux / Windows / macOS / Android 构建配置 |

**FFI 导出接口：**

```c
void*  engine_create();
void   engine_destroy(void* handle);
int    engine_initialize(void* handle);
int    engine_open(void* handle, const char* url, const char* headers_json);
void   engine_play(void* handle);
void   engine_pause(void* handle);
void   engine_seek(void* handle, double position_seconds);
void   engine_set_audio_track(void* handle, int index);
void   engine_set_subtitle_track(void* handle, int index);
double engine_get_position(void* handle);
double engine_get_duration(void* handle);
int    engine_get_state(void* handle);
void   engine_set_state_callback(void* handle, StateCallbackFn fn);
void   engine_set_position_callback(void* handle, PositionCallbackFn fn);
```

**C++ 文件清单：**

```
engine/
├── CMakeLists.txt
├── vcpkg.json
├── cmake/FindMPV.cmake
├── src/
│   ├── core/
│   │   ├── playback_engine.h / .cpp    # libmpv 封装
│   │   ├── media_source.h / .cpp       # 媒体源抽象
│   │   └── event_loop.h                # 事件循环
│   ├── emby/
│   │   └── emby_client.h / .cpp        # Emby C++ 客户端（可选）
│   └── ffi/
│       ├── flutter_bridge.h             # FFI 导出头文件
│       └── flutter_bridge.cpp           # FFI 实现
└── tests/
    └── test_playback.cpp
```

---

### Step 5：转码服务与高级功能

**目标：** 实现服务端转码调度，支持画质选择和带宽自适应。

| 子任务 | 层级 | 说明 |
|--------|------|------|
| 转码调度 | Go | 根据客户端能力决定 Direct Play / Transcode |
| gRPC 转码服务 | C++ | FFmpeg 转码流水线，暴露 gRPC 接口 |
| 画质切换 | Flutter | 手动选择分辨率/码率 |
| 带宽自适应 | Flutter + Go | 根据网速自动切换画质 |
| 硬件加速转码 | C++ | VAAPI / NVENC / VideoToolbox |
| AV1 支持 | C++ | AV1 解码器集成 |

---

### Step 6：体验打磨与平台适配

**目标：** 完善细节，发布可用版本。

| 子任务 | 层级 | 说明 |
|--------|------|------|
| Windows 适配 | Flutter | 键盘快捷键、窗口记忆、标题栏自定义 |
| macOS 适配 | Flutter | Touch Bar、菜单栏、原生窗口 |
| Android 适配 | Flutter | 画中画(PiP)、MediaSession 通知栏、Chromecast |
| 主题系统 | Flutter | 深色/浅色切换、自定义强调色 |
| 离线下载 | Flutter + Go | 断点续传、后台下载队列 |
| 音频直通 | C++ | Passthrough 到外部解码器 |
| CI/CD | GitHub Actions | 多平台自动构建 + 产物发布 |
| 性能优化 | 全栈 | 内存占用、启动速度、渲染帧率 |

---

## 七、各语言学习收益总结

| 语言 | 核心学习内容 |
|------|-------------|
| **Dart/Flutter** | 跨平台 UI 状态管理（Riverpod）、Platform Channel / FFI、动画系统、自适应布局、GDI 渲染 |
| **Go** | 并发模型（goroutine/channel）、HTTP 中间件链、JWT 认证、与 C 互操作（CGo）、gRPC、结构化日志 |
| **C++** | 现代 C++（C++17/20）、RAII/智能指针/移动语义、FFmpeg 多媒体处理、libmpv 封装、CMake 跨平台构建、Flutter FFI、gRPC C++、性能优化 |

---

## 八、关键原则

1. **每一步都有可运行的产出** — 不写纯设计文档，每阶段结束必须能跑起来
2. **先跑通再优化** — 初期用 media_kit，后期替换为自研 C++ 引擎
3. **Go 代理先于直连** — 初期 Flutter 不直连 Emby，通过 Go 网关代理，学习中间层架构
4. **不重复造轮子** — 播放核心用 libmpv，业务逻辑在上层自研
5. **CI/CD 从第一天开始** — 即使只有 Linux，也配置 GitHub Actions 处理跨平台构建
