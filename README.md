<div align="center">

# ✦ Aether Player

**基于 Emby 生态的跨平台媒体播放器**

![Flutter](https://img.shields.io/badge/Flutter-3.32+-02569B?logo=flutter&logoColor=white)
![Go](https://img.shields.io/badge/Go-1.24-00ADD8?logo=go&logoColor=white)
![C++](https://img.shields.io/badge/C++-17/20-00599C?logo=cplusplus&logoColor=white)
![License](https://img.shields.io/badge/License-GPL--3.0-blue)

<br/>

[English](#english) · [中文](#中文)

</div>

---

<a id="中文"></a>

## 🎬 关于项目

Aether Player 是一款**自研 Emby 媒体客户端**，支持视频播放、媒体库浏览、转码串流等功能。项目以学习为核心目标，采用 **Flutter + Go + C++** 三语言协作架构。

### ✨ 核心特性

| 特性 | 说明 |
|:-----|:-----|
| 🎥 **智能播放** | Direct Play / Transcode 自动切换，支持画质手动选择与自动续播下一集 |
| 📚 **媒体库浏览** | 海报墙、分类筛选、续播列表 |
| 🔍 **搜索** | 全局搜索电影 / 剧集 / 单集 / 音乐，输入防抖，结果直达详情页 |
| 🎨 **Celestial Glow UI** | 自研深色主题，玻璃态卡片 + 渐变光晕 |
| 📺 **TV 模式** | 大屏遥控器适配 |
| 🌐 **跨平台** | Linux / Windows / macOS / Android |
| 🔒 **本地安全代理** | Go 后端代理 Emby API：令牌存于系统安全存储而非明文文件；连接层拦截 SSRF（环回、链路本地与云元数据地址始终拒绝）；服务默认只监听 `127.0.0.1` |

### 🏗️ 架构

```
┌───────────────────────┐       localhost:19800       ┌──────────────┐
│    Flutter Client     │ ────── HTTP/REST ─────────→ │  Go Backend  │ ──→ Emby Server
│   (Dart / C++ FFI)    │                              │  (API 网关)   │
└───────────────────────┘                              └──────────────┘
         │                                                    │
    ┌────┴────┐                                          ┌────┴────┐
    │ UI 层   │ Riverpod + media_kit + 自研 FFI          │ 认证     │ JWT 签发
    │ 播放引擎 │ libmpv (C++ 封装 → Dart FFI)            │ 媒体代理  │ 元数据 / 图片
    │ 画质切换 │ PlaybackStrategy 智能决策               │ 转码调度  │ PlaybackInfo
    └─────────┘                                          │ 进度上报  │ Sessions API
                                                         └─────────┘
```

## 🚀 快速开始

### 环境要求

| 工具 | 版本 |
|:-----|:-----|
| Flutter | 3.32+ (stable) |
| Go | 1.24+ |
| CMake | 3.20+ |
| Ninja | 最新版 |
| libmpv | 开发包 (Linux) |

### 后端 (Go)

```bash
cd server

# 运行
go run ./cmd/api/

# 构建
go build -o aether-server ./cmd/api/

# 测试
go test ./...
```

**环境变量：**

| 变量 | 默认值 | 说明 |
|:-----|:-------|:-----|
| `PORT` | `19800` | HTTP 监听端口 |
| `BIND_ADDR` | `127.0.0.1` | 监听地址。默认只绑回环，仅供同机客户端访问；确需远程访问时显式设置（如 `0.0.0.0`） |
| `CORS_ALLOW_ORIGIN` | *(空 — 不输出跨域头)* | 允许的跨域来源。本地代理并非浏览器跨域场景，默认不开放；需填写**具体来源**，通配符 `*` 会被忽略 |
| `AETHER_BLOCK_PRIVATE_NETWORK` | *(空 — 允许私网)* | 设为 `true` 时一并拦截私网地址。家用 Emby 通常部署在局域网内，故默认放行；环回、链路本地与云元数据地址（`169.254.169.254`）**始终**拦截 |

### 前端 (Flutter)

```bash
cd app

# 安装依赖
flutter pub get

# 生成国际化文件
dart run slang

# 运行
flutter run

# 构建 Linux
flutter build linux --release
```

### 一体化构建 (CMake)

```bash
# 配置 + 构建 (Go 后端 + Flutter 客户端 + 打包)
cmake -B build -G Ninja
cmake --build build

# 产物位置
ls build/output/              # Go 二进制
ls app/build/linux/x64/release/bundle/  # Flutter 完整包
```

## 📦 CI / CD

每次推送到 `main` 或 `dev` 分支会自动运行 CI：

| Job | 内容 | 产物 |
|:----|:-----|:-----|
| **Go Backend** | vet → test → build | — |
| **Flutter Check** | analyze → test | — |
| **C++ Engine** | CMake 配置 → 编译 libmpv 封装库 | — |
| **Build Linux** | Go + Flutter + CMake 一体化 | `.tar.gz` |
| **Build Windows** | Go + Flutter 打包 | `.zip` / `.exe` |
| **Build Android** | Flutter APK + AAB | `.apk` / `.aab` |

**构建产物：** CI 通过后可在 Actions → 对应 Run → Artifacts 下载各平台构建包（保留 30 天）。

**发布版本：** 推送 `v*` 标签（如 `v1.0.0`）会自动创建 GitHub Release，附带 Linux / Windows / Android 全平台产物。

```bash
# 发布版本
git tag v1.0.0
git push origin v1.0.0
```

## 📁 项目结构

```
Aether-Player/
├── app/                          # Flutter 前端
│   ├── lib/
│   │   ├── models/               # 数据模型（容错解析）
│   │   ├── providers/            # Riverpod 状态管理
│   │   ├── screens/              # 页面 (首页、播放器、设置…)
│   │   ├── services/             # API 客户端、播放引擎、策略、错误日志
│   │   ├── theme/                # Celestial Glow 主题
│   │   ├── utils/                # 纯函数工具（剧集合并等）
│   │   └── widgets/              # 可复用组件
│   └── test/                     # 单元测试
├── server/                       # Go 后端
│   ├── cmd/api/                  # 入口（优雅关闭）
│   ├── internal/
│   │   ├── emby/                 # Emby API 客户端
│   │   ├── handler/              # HTTP 处理器
│   │   ├── middleware/           # 中间件（日志、CORS、体积限制）
│   │   └── security/             # SSRF 防护与输入净化（连接层强制）
│   └── mobile/                   # gomobile 绑定（Android AAR）
├── engine/                       # C++ 媒体引擎 (libmpv FFI)
│   ├── src/core/                 # PlaybackEngine 封装
│   └── src/ffi/                  # Flutter FFI 桥接
├── docs/                         # 设计文档
│   └── reports/                  # 代码审查报告（Bug / 修复方案 / 优化）
├── CMakeLists.txt                # 一体化构建
└── .github/workflows/ci.yml     # CI 流水线
```

## 🛠️ 技术栈

| 层级 | 技术 |
|:-----|:-----|
| **前端** | Flutter 3.32+ / Dart, Riverpod, media_kit, slang (i18n) |
| **后端** | Go 1.24, net/http, JWT |
| **引擎** | C++17/20, libmpv, dart:ffi |
| **构建** | CMake + Ninja, GitHub Actions |
| **设计** | Celestial Glow 深色主题, Sora + DM Mono 字体 |

## ⚠️ 已知限制

以下为当前版本的实际状态，避免按 README 描述使用时产生落差：

| 项 | 状态 |
|:---|:---|
| **原生 C++ 引擎** | 设置页可选，但**尚不可用**：FFI 事件回调仍使用 `Pointer.fromFunction`，而 libmpv 在独立线程触发事件，需改用 `NativeCallable.listener` 重构。默认引擎为 media_kit，功能正常 |
| **界面语言** | slang i18n 框架已接入，但播放器、设置页等大量文案仍为硬编码中文，切换到 English 后界面不会完全英文化 |
| **部分设置项** | 硬件加速、音频直通、字幕大小、默认音轨/字幕语言、带宽限制等已持久化，但尚未接线到播放引擎，调整后暂无实际效果 |
| **Android 构建** | 依赖的 `app/android/app/libs/aether-server.aar` 未纳入版本控制，需由 CI 现场通过 `gomobile bind` 生成；本地直接构建 APK 会因缺失该文件失败 |
| **播放地址中的令牌** | 转码/直连流地址仍以 `api_key=` 查询参数携带令牌，可能进入访问日志，待改为经本地代理转发 |

完整的缺陷清单与修复方案见 [`docs/reports/`](docs/reports/)。

## 🧪 测试

```bash
# Flutter — 静态分析与单元测试
cd app
flutter analyze
flutter test

# Go — vet 与单元测试（含 SSRF 绕过手法回归）
cd server
go vet ./...
go test ./...
```

C++ 引擎需 `libmpv-dev`，通过 `cmake -B build/engine -S engine && cmake --build build/engine` 验证编译。

## 📄 许可证

本项目基于 [GNU General Public License v3.0](LICENSE) 开源。

---

<a id="english"></a>

## About

**Aether Player** is a cross-platform Emby media client built with Flutter, Go, and C++. It features smart playback (Direct Play / Transcode), a custom dark UI theme (Celestial Glow), and a local Go backend that proxies Emby API calls securely.

### Quick Start

```bash
# Backend
cd server && go run ./cmd/api/

# Frontend
cd app && flutter pub get && dart run slang && flutter run

# Full build (CMake)
cmake -B build -G Ninja && cmake --build build
```

### Testing

```bash
# Flutter
cd app && flutter analyze && flutter test

# Go (includes SSRF bypass regression tests)
cd server && go vet ./... && go test ./...
```

### CI/CD

- Push to `main`/`dev` → CI runs (Go vet/test, Flutter analyze/test, C++ engine compile) + multi-platform artifacts uploaded (Linux, Windows, Android)
- Push `v*` tag → GitHub Release created with all platform build artifacts

### Known Limitations

- **Native C++ engine**: selectable in settings but **not yet usable** — the FFI event callback still uses `Pointer.fromFunction` while libmpv fires events on a separate thread; it needs to be reworked with `NativeCallable.listener`. The default media_kit engine works normally.
- **Localization**: the slang i18n framework is wired up, but many strings (player, settings) are still hardcoded Chinese, so switching to English does not fully translate the UI.
- **Some settings**: hardware acceleration, audio passthrough, subtitle size, default track languages and bandwidth limit are persisted but not yet wired into the playback engine.
- **Android build**: `app/android/app/libs/aether-server.aar` is not checked in; CI generates it via `gomobile bind`. A local APK build fails without it.

See [`docs/reports/`](docs/reports/) for the full defect list and remediation plan.

### License

[GPL-3.0](LICENSE)
