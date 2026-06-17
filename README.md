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
| 🎥 **智能播放** | Direct Play / Transcode 自动切换，支持画质手动选择 |
| 📚 **媒体库浏览** | 海报墙、分类筛选、搜索、续播列表 |
| 🎨 **Celestial Glow UI** | 自研深色主题，玻璃态卡片 + 渐变光晕 |
| 📺 **TV 模式** | 大屏遥控器适配 |
| 🌐 **跨平台** | Linux / Windows / macOS / Android |
| 🔒 **安全代理** | Go 后端代理 Emby API，Token 不暴露给前端 |

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
| `CORS_ALLOW_ORIGIN` | *(空 — 允许所有)* | CORS 来源 |

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
│   │   ├── models/               # 数据模型
│   │   ├── providers/            # Riverpod 状态管理
│   │   ├── screens/              # 页面 (首页、播放器、设置…)
│   │   ├── services/             # API 客户端、播放引擎、策略
│   │   ├── theme/                # Celestial Glow 主题
│   │   └── widgets/              # 可复用组件
│   └── test/                     # 测试
├── server/                       # Go 后端
│   ├── cmd/api/                  # 入口
│   └── internal/
│       ├── emby/                 # Emby API 客户端
│       ├── handler/              # HTTP 处理器
│       └── middleware/           # 中间件
├── engine/                       # C++ 媒体引擎 (libmpv FFI)
│   ├── src/core/                 # PlaybackEngine 封装
│   └── src/ffi/                  # Flutter FFI 桥接
├── docs/                         # 设计文档
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

### CI/CD

- Push to `main`/`dev` → CI runs + multi-platform artifacts uploaded (Linux, Windows, Android)
- Push `v*` tag → GitHub Release created with all platform build artifacts

### License

[GPL-3.0](LICENSE)
