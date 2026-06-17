# Aether Dev 分支调试报告 — 2026-06-18

## 已修复问题

### 1. TranslationProvider 未包裹（白屏）
- **文件**: `app/lib/main.dart`
- **原因**: `runApp` 没有包裹 `TranslationProvider`，导致 `app.dart:24` 调用 `TranslationProvider.of(context)` 崩溃
- **修复**: 在 `ProviderScope` 外层包裹 `TranslationProvider`

### 2. BackendService detached 模式异常
- **文件**: `app/lib/services/backend_service.dart`
- **原因**: `ProcessStartMode.detached` 模式下访问 `exitCode` 抛出 `Bad state: Process is detached`
- **修复**: 移除 `mode: ProcessStartMode.detached`，使用默认 normal 模式

### 3. BackendService 端口冲突
- **文件**: `app/lib/services/backend_service.dart`
- **原因**: 应用启动时尝试启动新 Go 后端进程，但端口已被占用（手动启动的后端），导致 `Process exited with code 1`
- **修复**: 添加 `_isPortInUse()` 方法，检测端口是否已被占用，跳过重复启动

### 4. 侧边栏布局溢出
- **文件**: `app/lib/screens/shell_screen.dart`
- **原因**: `_Sidebar` 的 Column 中 library 按钮过多，溢出 73 像素
- **修复**: 将 library 按钮区域包裹在 `Expanded` + `SingleChildScrollView` 中

### 5. ParentDataWidget 错误
- **文件**: `app/lib/widgets/episode_card.dart`
- **原因**: `Positioned.fill` 放在了 `AnimatedOpacity` 内部（Positioned 必须是 Stack 的直接子级）
- **修复**: 调换 `Positioned.fill` 和 `AnimatedOpacity` 的顺序

### 6. 播放请求头缺失
- **文件**: `app/lib/services/api_client.dart` + `app/lib/providers/player_provider.dart`
- **原因**: `getPlaybackInfoFull()` 和 `getTranscodeStreamUrl()` 使用 `_get()` 时未传递 Go 后端必需的 `X-Emby-Server`、`X-Emby-Token`、`X-Emby-User` 请求头，导致后端返回 400 错误
- **修复**: 改用 `_dio.get()` 并添加所需 headers，调用处传入 serverUrl/token/userId

### 7. Google Fonts 异步崩溃
- **文件**: `app/lib/main.dart` + `app/lib/theme/app_theme.dart`
- **原因**: `google_fonts` 异步加载字体失败时抛出未处理异常，导致应用崩溃
- **修复**: 
  - `main.dart`: 使用 `runZonedGuarded` 包裹整个应用，捕获未处理异步异常
  - `main.dart`: 设置 `FlutterError.onError` 捕获 Flutter 渲染错误
  - `app_theme.dart`: `GoogleFonts.soraTextTheme()` 和 `GoogleFonts.dmMono()` 添加 try-catch 回退到系统字体

### 8. CMakeLists.txt Ninja 构建错误
- **文件**: `CMakeLists.txt`
- **原因**: `cmake -E echo` 的 `\n` 在 Ninja 中被错误解析；`|` 被 shell 解释为管道符
- **修复**: 
  - control 文件改用多行 `cmake -E echo` + `>>` 追加
  - `|` 转义为 `\\|`

## 待解决问题

### 9. 图片加载 502
- **症状**: `HTTP request failed, statusCode: 502`，`X-Emby-Server` 为空
- **涉及文件**: `app/lib/screens/home_tab.dart` 等多处
- **原因**: `_serverUrl` 异步加载，首次渲染时为 null，传入 Image.network 的 headers 中为空字符串
- **建议修复**: 
  - 方案 A: 在 `_serverUrl` 为 null 时显示占位图而非请求网络图片
  - 方案 B: 使用 Riverpod 管理 serverUrl，确保 widget 构建前已就绪

### 10. 视频未播放（texture 1x1）
- **症状**: media_kit 初始化成功，`NativeVideoController: Texture ID` 正常，但 texture 尺寸为 1x1
- **涉及文件**: `app/lib/screens/player_page.dart` + `app/lib/providers/player_provider.dart`
- **可能原因**:
  - stream URL 无效（空或相对路径）
  - Emby 返回的 `DirectStreamUrl` 是相对路径，缺少服务器前缀
  - `_engine.open()` 调用失败但被 catch 吞掉
- **建议排查**: 
  - 在 `loadAndPlay()` 的 catch 块中添加 UI 错误提示
  - 打印 `streamUrl` 的实际值
  - 检查 `PlaybackStrategy.auto()` 返回的 URL 是否为完整 URL

## 构建环境信息
- Go 后端: `build/output/aether-server`
- Flutter: `/home/altair/dev/flutter/bin/flutter`
- 平台: Linux x64
- 代理: 需通过 PATH 注入 Go 后端路径
- dpkg-deb: 未安装，.deb 包使用 `ar` 手动打包
