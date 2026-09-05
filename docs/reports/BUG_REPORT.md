# Aether Player — Bug 报告

> 审查分支：`dev`（起点 commit `1343f6a`）
> 审查日期：2026-09-05
> 审查范围：Flutter 客户端（`app/`，72 个 Dart 文件）、Go 服务端（`server/`，9 个文件）、C++ 播放引擎（`engine/`，4 个文件）
> 标注说明：**[已核验]** = 通过阅读源码逐行确认；`flutter analyze` 对 `app/lib` 输出 **No issues found**，故下列均为静态分析无法发现的语义 / 逻辑 / 安全缺陷。

---

## 一、P0 — 崩溃、数据丢失与安全问题

### BUG-001 播放器 UI 完全不随播放状态刷新 [已核验]

**位置**：`app/lib/screens/player_page.dart:414`

```dart
@override
Widget build(BuildContext context) {
  final state = _playerController?.currentState;   // ← 直接读取，无监听
```

`PlayerController` 定义于 `app/lib/providers/player_provider.dart:169`，是 `StateNotifier<PlayerUiState>`，但在 `player_page.dart:134` 被手动 `new` 出来，**全文件没有任何 `addListener` / `removeListener` / `ref.watch`**（已 grep 确认：`player_page.dart` 中 `addListener|removeListener|ref.watch|ref.listen` 零命中）。

**影响**：`StateNotifier` 的状态变更不会触发 `setState`。进度条、播放/暂停图标、缓冲指示、时长文本、错误提示全部静止，只在其它偶发 `setState`（如 seek 手势指示器）时才被动刷新一次。**这是播放器最核心的功能缺陷**。

**修复思路**：在 `initState` / 控制器创建后注册监听，`dispose` 时移除：

```dart
controller.addListener(_onPlayerStateChanged);
// ...
void _onPlayerStateChanged(PlayerUiState _) {
  if (mounted) setState(() {});
}
```

---

### BUG-002 Emby 访问令牌明文写入 SharedPreferences [已核验]

**位置**：`app/lib/services/storage_service.dart:19`、`app/lib/providers/auth_provider.dart:70-76`

```dart
// storage_service.dart:19 —— 明文
await prefs.setString(_tokenKey, token);

// auth_provider.dart:70-76 —— 双写
await _secureStorage.saveToken(result.token);      // 安全存储
await _storageService.saveAuthData(
  token: result.token,                             // 又写一份明文
  ...
```

**影响**：
1. 令牌以明文存于 `shared_prefs/*.xml`，Android 上未加密、桌面端为明文 XML，任何拿到设备文件读取权限的进程都能直接窃取 Emby 完整访问权。
2. 双份存储导致一致性隐患：`tryAutoLogin`（`auth_provider.dart:121`）读 secure storage，而 `StorageService.getToken()` 读 prefs，两条路径可能取到不同值。
3. 项目已引入 `flutter_secure_storage` 并封装了 `SecureStorageService`，明文副本属冗余且降低安全性。

**修复思路**：从 `StorageService.saveAuthData` 移除 `token` 参数与 `_tokenKey`，仅持久化 `serverUrl` / `userId` / `userName`；令牌唯一存放于 secure storage。同时在 `clearAuthData` 中清理历史遗留的 `auth_token` 键，避免旧版本用户升级后明文令牌残留。

---

### BUG-003 Go 代理存在可绕过的 SSRF，且大部分入口无校验 [已核验]

**位置**：`server/internal/handler/proxy.go:22-39`、`server/internal/emby/client.go`（全部方法）

```go
// proxy.go:35 —— 唯一的校验逻辑
host := u.Hostname()
if strings.HasPrefix(host, "169.254.") || host == "0.0.0.0" {
    return ...("blocked host")
}
```

**绕过方式（全部有效）**：
| 手法 | 示例 | 是否被拦 |
|:--|:--|:--|
| 环回地址 | `http://127.0.0.1:8080/` | ❌ 放行 |
| 主机名 | `http://localhost/` | ❌ 放行 |
| 私网段 | `http://10.0.0.1/`、`http://192.168.1.1/` | ❌ 放行 |
| 十进制 IP | `http://2852039166/` = `169.254.169.254` | ❌ 放行（字符串前缀不匹配） |
| IPv6 | `http://[::1]/` | ❌ 放行 |
| 重定向 | 合法 Emby 地址返回 302 → 内网 | ❌ 放行（`proxy.go:101` 的 `http.Client` 默认跟随重定向） |

**更严重**：`validateServerURL` **仅在 catch-all 代理中被调用一次**（`grep -rn 'validateServerURL' server/` 仅 3 处命中：定义 1、注释 1、调用 1 @ `proxy.go:56`）。而 `library.go:22`、`playback.go:27`、`user.go:29`、`auth.go:41/66` 从 `X-Emby-Server` 头 / `server_url` 字段取到地址后**未经任何校验**直接交给 `emby.Client` 发起请求。

**影响**：本机代理可被用作跳板探测内网服务、访问云元数据接口（`169.254.169.254` 可窃取云主机临时凭据）。结合 BUG-004 的 `0.0.0.0` 绑定，攻击面扩大到整个局域网。

**修复思路**：抽出统一的 `validateServerURL`，在**所有** handler 入口调用；校验不能只看字符串，须在 DNS 解析后判断最终 IP 是否属于私网/环回/链路本地段，并通过自定义 `DialContext` 在真正建连前二次校验（防 DNS rebinding），同时设置 `CheckRedirect` 拒绝跳转到非白名单地址。

---

### BUG-004 服务监听所有网卡 + CORS 全开 + 无调用方鉴权 [已核验]

**位置**：`server/cmd/api/main.go:62`、`server/internal/middleware/middleware.go:19-26`

```go
// main.go:62 —— 绑定所有网卡
if err := http.ListenAndServe(":"+port, h); err != nil {

// middleware.go:21-26 —— CORS 默认 *
allowedOrigin := os.Getenv("CORS_ALLOW_ORIGIN")
if allowedOrigin == "" {
    allowedOrigin = "*"
}
w.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
w.Header().Set("Access-Control-Allow-Headers", "..., X-Emby-Server, X-Emby-Token, ...")
```

**矛盾点**：`README.md:40` 与 `app/lib/services/api_client.dart:8` 均声明架构为 `localhost:19800` 本地代理，`server/mobile/mobile.go:47` 也正确绑定了 `127.0.0.1`，唯独进程版 `main.go` 绑定了 `0.0.0.0`。

**影响**：
1. 同网段任意主机可直接调用该代理，配合 BUG-003 打内网。
2. `Access-Control-Allow-Origin: *` + 允许 `X-Emby-Server` / `X-Emby-Token` 自定义头 → 用户浏览器中**任意恶意网页**都能驱动本机代理发起请求并跨域读取响应，还可窃取请求中的 `X-Emby-Token`。
3. 无任何调用方身份校验，本地任意进程均可访问。

**修复思路**：绑定 `127.0.0.1`；CORS 默认收敛（不再 `*`）；启动时生成随机 Bearer token，由 Flutter 端注入到每个请求，服务端校验。

---

### BUG-005 C++ 将 `int*` 当作 `int64_t*` 传给 mpv（未定义行为） [已核验]

**位置**：`engine/src/core/playback_engine.cpp:132-133`、`engine/src/core/playback_engine.cpp:148-149`

```cpp
int mpv_id = _audioTracks[index].index + 1;
mpv_set_property(_handle, "aid", MPV_FORMAT_INT64, &mpv_id);   // ← int* 传给 INT64
```

```cpp
int mpv_id = _subtitleTracks[index].index + 1;
mpv_set_property(_handle, "sid", MPV_FORMAT_INT64, &mpv_id);   // ← 同样错误
```

**影响**：`MPV_FORMAT_INT64` 要求 mpv 从该指针读取 8 字节，而 `int` 只有 4 字节。mpv 会读到栈上相邻的 4 字节垃圾数据，实际取到的 track ID 为 `(垃圾 << 32) | 期望值`，属未定义行为：音轨/字幕切换静默失败、切到错误轨道，或在某些平台直接崩溃。

**修复思路**：声明为 `int64_t mpv_id = ...;`。两处，各改一行。

---

### BUG-006 FFI 回调机制错误：mpv 事件线程直调 `Pointer.fromFunction` [已核验]

**位置**：`app/lib/services/native_engine.dart:199-248`、`engine/src/core/playback_engine.cpp:211`

`Pointer.fromFunction` 注册的回调只能在**同一 Dart isolate 且已 attach 的线程**上调用。而 libmpv 的事件在 `playback_engine.cpp` 独立的 eventLoop 线程中触发，回调需同步 attach 进 Dart isolate；当 isolate 正忙时会阻塞 mpv 事件循环，甚至死锁。Dart FFI 官方对跨线程回调的要求是使用 `NativeCallable.listener`。

**附加缺陷**：
- `native_engine.dart:260` 用全局静态 `_instance` 单例转发回调，创建第二个引擎实例会覆盖前者。
- `native_engine.dart:429-439` 的 `dispose` 先关闭 `StreamController` 再调用 `_destroy`，此间 C 侧回调仍可能触发并 `add` 到已关闭的 controller，抛 `StateError`。

**影响**：选择"原生引擎"时随机崩溃 / 卡死。

**修复思路**：改用 `NativeCallable.listener`（异步投递到 isolate 事件循环，线程安全）；`dispose` 顺序改为先注销 C 侧回调 → `_destroy` → 再关流；移除全局单例，改为每实例持有回调句柄。

---

### BUG-007 持久化的播放引擎与语言设置永不恢复 [已核验]

**位置**：`app/lib/providers/settings_provider.dart:16`、`app/lib/providers/locale_provider.dart:11`

两处 `load()` 方法均已实现，但**全工程无任何调用方**（grep 确认：仅有 `setLocale` @ `settings_tab.dart:359,369`、`setEngine` @ `settings_tab.dart:802` 被调用）。

叠加 `app/lib/main.dart:31` 的 `LocaleSettings.useDeviceLocale()` 无条件覆盖，导致：

**影响**：用户在设置页选择"原生 mpv 引擎"或"English"后，重启应用一律回到默认值（`player_page.dart:130` 读到的永远是 `PlayerEngineType.mediaKit`）。设置项形同虚设。

**修复思路**：在 `main()` 中 `runApp` 之前 `await` 两个 `load()`；语言恢复优先于 `useDeviceLocale()`（仅当无持久化值时才回退到设备语言）。

---

### BUG-008 全局异常被静默吞掉 [已核验]

**位置**：`app/lib/main.dart:23-26`、`app/lib/main.dart:59-62`

```dart
FlutterError.onError = (details) {
  debugPrint('[FlutterError] ${details.exception}');
  // 不调用 FlutterError.presentError，避免崩溃
};
...
(error, stackTrace) {
  debugPrint('[ZoneError] $error');
  // 捕获未处理的异步异常，避免应用崩溃
},
```

**影响**：`debugPrint` 在 release 构建中被剥离（`kReleaseMode` 下 `debugPrint` 仍输出到 stdout，但 release 包无控制台可观察），且注释明确说明**故意不调用 `FlutterError.presentError`**。结果是所有 Flutter 框架错误与未处理异步异常都被完全吞没：无红屏、无上报、无日志，线上问题无从定位。

**修复思路**：保留捕获但恢复 `FlutterError.presentError(details)`（debug 下可见红屏，release 下静默），并在 `kReleaseMode` 下写入本地错误日志文件或上报通道，而非仅 `debugPrint`。

---

### BUG-009 手机媒体库图片全部加载失败 [已核验]

**位置**：`app/lib/screens/phone_library_screen.dart:288`、`:478`

```dart
// phone_library_screen.dart:288 —— 错误：拼到 Emby 服务器地址上
'$_serverUrl/api/images/${item.id}/Primary?maxWidth=300';
// phone_library_screen.dart:478 —— 同样错误
? '$serverUrl/api/images/${item.id}/Primary?maxWidth=300'
```

对照正确写法（`app/lib/screens/home_tab.dart:194`、`:571`）：

```dart
'${ApiClient.proxyBaseUrl}/api/images/${item.id}/Primary?maxWidth=300';
```

**根因**：`/api/images/...` 是**本地 Go 代理**的路由（`server/cmd/api/main.go` 中注册），而 `_serverUrl` 是远端 Emby 服务器地址（`phone_library_screen.dart:50` 从 storage 读出）。向 Emby 直接请求 `/api/images/` 会 404。

**影响**：`PhoneLibraryScreen` 中所有海报 / 封面图不显示。

**修复思路**：统一改用 `ApiClient.proxyBaseUrl`，并保留 `X-Emby-Server` 头（该文件 `:322` 已正确设置）让代理转发。

---

## 二、P1 — 功能性 Bug

### BUG-010 搜索功能是空壳 [已核验]

- `app/lib/screens/shell_screen.dart:47`：`SearchOverlay.show(context)` 未传 `onSubmitted` 回调，提交后仅关闭浮层，不执行任何搜索。
- `app/lib/screens/home_tab.dart:932`：`_SearchDialog` 仅渲染占位文本 `搜索 "$_query"…`，从不调用接口。
- `app/lib/services/api_client.dart:233`：`search()` 接口已实现，但**全工程零调用方**。

**影响**：`README.md:31` 宣称的"搜索"特性实际不可用。

### BUG-011 "切换账户"陷入死循环，用户无法退出当前账号 [已核验]

**位置**：`app/lib/screens/settings_tab.dart:174-179`

直接 `pushAndRemoveUntil` 跳转到 `ServerSelectionScreen`，但**未先 `logout()`**。而 `ServerSelectionScreen.initState`（`:46`）会调用 `tryAutoLogin()`，用仍然有效的旧令牌立即跳回 `ShellScreen`。

对照正确实现：`app/lib/screens/home_tab.dart:420-427` 先 `logout()` 再跳转。

**影响**：点击"切换账户"后页面闪一下又回到原账户，功能完全不可用。

### BUG-012 自动播放下一集全链路断裂 [已核验]

`PlayerPage` 的 `seriesId` / `seasonId` / `episodeIndex` 三个参数在**全部 3 个调用点均未传递**：
- `app/lib/screens/episode_detail_screen.dart:126`
- `app/lib/screens/media_detail_screen.dart:255`、`:511`

导致 `player_page.dart:325` 的 `_checkAutoPlayNext` 恒早退，`:520` 的 `onSkipNext` 恒为 `null`。另外 `_nextEpisodeId` 仅在播放**完成后**才被填充，因此"下一集"按钮即使显示也无法点击跳转。

**影响**：连续追剧体验缺失，`README` 宣称的智能播放能力打折。

### BUG-013 字幕被强制选中第一条轨道 [已核验]

`app/lib/screens/episode_detail_screen.dart:131` 传入默认值 `_selectedSubtitleIndex = 0`，而 `player_page.dart:166` 判断为：

```dart
if (widget.subtitleTrackIndex != null) {          // 恒真（默认 0 而非 null）
  await controller.selectSubtitleTrack(widget.subtitleTrackIndex!);
}
```

与紧邻的音轨判断（`player_page.dart:163`，使用 `!= null && > 0`）不一致。

**影响**：用户从未选择字幕时，播放器仍强制启用第 0 条字幕轨。应传 `null` 表示"未选择"。

### BUG-014 `tryAutoLogin` 不校验令牌有效性，失败时首页静默空白 [已核验]

**位置**：`app/lib/providers/auth_provider.dart:120-138`

```dart
state = state.copyWith(
  authResult: AuthResult(
    token: token,
    user: UserInfo(id: userId, name: userName),
    server: ServerInfo(serverName: 'Saved Server', version: '', id: ''),  // ← 伪造
  ),
);
return true;   // ← 无条件返回成功
```

叠加 `app/lib/providers/home_provider.dart:117` 的 `catch (_)` 空吞异常。

**影响**：令牌过期时应用仍进入 `ShellScreen`，但所有请求返回 401 且异常被静默吞掉，用户看到**完全空白的首页且无任何错误提示或重新登录引导**。

**修复思路**：自动登录后调用 `/System/Info` 或用户接口验证令牌；401 时清除凭据并回登录页，并给出可读提示。

### BUG-015 `copyWith` 永远清空 error 字段 [已核验]

**位置**：`app/lib/providers/auth_provider.dart:33`、`app/lib/providers/home_provider.dart:37`

```dart
return AuthState(
  isLoading: isLoading ?? this.isLoading,
  error: error,                              // ← 缺少 ?? this.error
  serverInfo: serverInfo ?? this.serverInfo,
  authResult: authResult ?? this.authResult,
);
```

**影响**：任何一次未显式传 `error` 的状态更新都会抹掉已有错误信息；反之也无法在保留 error 的同时更新其它字段。与其余三个字段的写法不一致，属明显笔误。

### BUG-016 `setState` 缺少 `mounted` 检查（跨 async gap） [已核验]

- `app/lib/screens/login_screen.dart:30-34`：`await connectToServer(...)` 后直接 `setState`，若期间页面被 pop 则抛异常。
- `app/lib/providers/player_provider.dart:421`：`switchQuality` 中 `await` 之后写 `state`。
- `app/lib/providers/player_provider.dart:410`：`_engine.stop()` 后无状态检查。

### BUG-017 剧集合并键冲突 + O(n²) 性能 [已核验]

**位置**：`app/lib/utils/episode_utils.dart:12`

```dart
ep.indexNumber > 0 ? ep.indexNumber : raw.indexOf(ep)
```

**影响**：若某集 `indexNumber == 3`，而另一无编号集恰好位于列表第 3 位，两者会共用键 `3` 被错误合并，导致剧集丢失。且 `raw.indexOf(ep)` 在循环内调用，整体为 O(n²)。

**修复思路**：为无编号集使用独立负数键序列，或改用 `(indexNumber, id)` 复合键；用索引变量替代 `indexOf`。

### BUG-018 `pubspec.yaml` 缺少移动端 media_kit 运行库 [已核验]

**位置**：`app/pubspec.yaml:26-27` — 仅声明 `media_kit_libs_linux` 与 `media_kit_libs_windows`。

**影响**：`README.md:34` 宣称支持 Android，但 Android 上 `MediaKit.ensureInitialized()` 会因缺少原生库而失败。

### BUG-019 画质回退分支丢失 Direct Play 地址 [已核验]

**位置**：`app/lib/providers/player_provider.dart:405`

切回"原始画质"时使用 `_currentStreamUrl`，但若上一次为转码播放，该字段已是**转码 URL**，因此"原始画质"实际仍在播转码流。

**修复思路**：分别缓存 `_directPlayUrl` 与 `_transcodeUrl`，按目标画质取对应字段。

### BUG-020 代理 30 秒超时截断长响应与流式内容 [已核验]

**位置**：`server/internal/handler/proxy.go:101`

```go
client := &http.Client{Timeout: 30 * time.Second}
```

`http.Client.Timeout` 覆盖**整个请求周期，包含 body 读取**。`proxy.go:123` 的 `io.Copy(w, resp.Body)` 对大响应（图片包、元数据批量查询）或流式内容会在 30 秒被腰斩。同时每请求新建 `http.Client` 导致 TCP 连接无法复用。

**修复思路**：使用包级共享 `http.Client`，不设整体 `Timeout`，改用 `Transport.ResponseHeaderTimeout` 只约束首字节等待，并对流式响应使用 `http.Flusher` 及时刷新。

### BUG-021 上游查询参数未做 URL 编码 [已核验]

**位置**：`server/internal/emby/client.go:279-289`、`:381-382`

`SearchTerm=` 后直接拼接原始字符串。搜索词含 `&`、空格、`#`、中文时会破坏查询串或注入额外上游参数。

**修复思路**：改用 `url.Values{...}.Encode()`。

### BUG-022 SIGTERM 后应用挂死，Go 子进程管道无人消费 [已核验]

- `app/lib/services/backend_service.dart:231-241`：Dart 接管 SIGTERM/SIGINT 后抑制了默认退出行为，但 `_emergencyStop`（`:246`）只杀子进程、**从不调用 `exit()`** → 桌面端关闭窗口后主进程残留。且内部使用 `Future.delayed` 发送 SIGKILL，进程退出时事件循环可能已停止，延迟任务不会执行。
- `app/lib/services/backend_service.dart:107-117`：`Process.start` 后从不 listen `stdout` / `stderr`，而 `server/internal/middleware/middleware.go:13-15` **每个请求写两条日志** → Dart 侧管道缓冲无限增长（内存泄漏），且后端日志全部丢失，排障困难。

### BUG-023 mpv `buffering` 属性不存在，缓冲状态永不触发 [已核验]

**位置**：`engine/src/core/playback_engine.cpp:39`、`:267`

```cpp
mpv_observe_property(_handle, 0, "buffering", MPV_FORMAT_FLAG);
```

libmpv 无 `buffering` 属性（正确名称为 `cache-buffering-state` 或 `paused-for-cache`）。`mpv_observe_property` 对不存在的属性静默失败，导致 `:267` 的 `handleEvent` 分支成为死代码。

**影响**：网络卡顿时 UI 无任何缓冲反馈。

---

## 三、P2 — 质量与体验缺陷

| 编号 | 问题 | 位置 |
|:--|:--|:--|
| BUG-024 | `_autoPlayTimer`（每秒触发）未在 `dispose` 中 cancel；`reportStopped()` 未 await 即 `dispose()`，停止上报可能丢失 | `player_page.dart:176-194`、`:371` |
| BUG-025 | 进度条 Slider 只实现 `onChanged`，拖动中每像素触发一次 `seek`（provider 侧未 await、无节流）；`PlayerUiState.isSeeking` 定义了却从未使用 | `player_page.dart:891-894`、`player_provider.dart:438` |
| BUG-026 | 星空动画每帧重建 80 个 `Random` 星星 + 80 个 `MaskFilter.blur`，`AnimatedBuilder` 每帧新建 painter，CPU/GPU 浪费显著 | `server_selection_screen.dart:75-83`、`:368` |
| BUG-027 | 大量设置项为死配置：硬件加速、音频直通、字幕大小、默认音轨/字幕语言、带宽限制、噪点/动画开关只写 SharedPreferences，**无任何消费方**；且每次 `SettingsService()` 新建实例，未复用已有的 `settingsServiceProvider` | `settings_tab.dart:43`、`:224`，`settings_modal.dart` |
| BUG-028 | 死代码：`VideoOsd`、`MiniPlayBar`、`MediaCard`、`SearchHintCard`、`AudioPlayerPage`、`ApiClient.getImageUrl`（`:221`）均零引用；原生引擎视频渲染仅为占位文案（`player_page.dart:431-456`）；`native_engine.dart:444` `loadExternalSubtitle` 为空 TODO | 见左 |
| BUG-029 | i18n 名存实亡：slang 框架已接入，但 `app.dart:68,77,92`、`player_page.dart`（"即将播放下一集/取消/立即播放/设置/倍速/音轨/字幕"）、`settings_tab.dart` 全部、`home_tab.dart:204,378,412,738` 等大量中文硬编码，切 English 后界面基本仍是中文 | 见左 |
| BUG-030 | 错误提示直接展示 `e.toString()`（泄漏内部实现且未本地化）；多处 `catch (_)` 空吞异常 | `login_screen.dart:328`、`home_tab.dart:269`、`player_page.dart:538`；`home_provider.dart:117`、`player_provider.dart:580,605`、`episode_detail_screen.dart:75` |
| BUG-031 | 模型解析隐患：`media_models.dart:186` 出现 `json['Type'] as String? ?? json['Type'] as String? ?? ''` 重复无意义表达式；`auth_models.dart:14-16` 未做类型 cast，服务器返回非字符串会抛 `TypeError`；`saved_server.dart:30-35` 全部强制 cast，脏数据会让 `getSavedServers` 整体抛异常且外层无 try/catch（`storage_service.dart:58`） | 见左 |
| BUG-032 | 测试覆盖近乎为零：`app/test/widget_test.dart` 仅 1 个用例且只测错误页文案；providers / playback_strategy / episode_utils 等纯逻辑无任何单测 | `app/test/` |
| BUG-033 | Android 构建必然失败：`app/android/app/build.gradle.kts:42` 依赖 `libs/aether-server.aar`，但 `libs/` 目录为空，Makefile 与根 CMakeLists 均无 `gomobile bind` 目标，`MainActivity.kt:11` 的 import 无法解析（仅 CI 中通过 `ci.yml:248` 现场生成） | 见左 |
| BUG-034 | `.deb` 打包的 control 文件从未生成：根 `CMakeLists.txt:200-215` 使用 `cmake -E echo "..." > ${DEB_DIR}/DEBIAN/control`，但 `add_custom_command` 不经过 shell，`>` 被当作 echo 的字面参数 → `DEBIAN/control` 不存在 → `dpkg-deb --build`（`:217`）失败 | 见左 |
| BUG-035 | `ToggleFavorite` 语义反转隐患：`client.go:754-757` 中 `isFavorite=true → UnmarkFavorite`（把入参当"当前态"），而 `user.go:35` 与 `api_client.dart:473` 的字段名暗示"目标态"，一旦接线极易做反 | 见左 |
| BUG-036 | 请求头注入：`proxy.go:98` 将来自请求头的 `deviceID` 未转义拼进 `X-Emby-Authorization` 的引号内，可注入 `"` 篡改授权字段语义 | 见左 |
| BUG-037 | 无 graceful shutdown / Slowloris 防护：`main.go:62` 裸 `ListenAndServe`，无 `Server.ReadHeaderTimeout`（`mobile.go:60` 有，进程版没有）、无信号处理，升级或退出时在途请求被斩断 | 见左 |
| BUG-038 | 令牌泄漏进 URL：`client.go:503`、`:510`、`:813` 将 `api_key=<token>` 拼入 stream URL 返回客户端（`playback.go:92`），令牌会进入 mpv 与 Emby 访问日志；且 `streamUrl` 直指 Emby 绕过本地代理，与"全部经 19800"的架构约定不符 | 见左 |
| BUG-039 | 路由表双份维护已分叉：`mobile.go:147-226` 与 `main.go:22-117` 为复制粘贴，改一处漏一处 | 见左 |
| BUG-040 | 后端健康检查把任意占用 19800 端口且返回 200 的进程当作自家后端（无法识别身份）；健康检查失败重入 `start()`（`:273`）可能叠加拉起多个 Go 进程，且重复注册 SIGTERM/SIGINT 监听无去重 | `backend_service.dart:46`、`:121-131`、`:227-241` |

---

## 四、P3 — 优化建议（详见 `OPTIMIZATION_REPORT.md`）

| 编号 | 问题 | 位置 |
|:--|:--|:--|
| BUG-041 | 全站 `Image.network` 无磁盘缓存、未设 `cacheWidth`，按原始尺寸解码大图 | `home_tab.dart:603`、`media_card.dart:201`、`media_detail_screen.dart:524` |
| BUG-042 | 全工程无 `Semantics`；`_SeeAllButton` 字号 10.9 过小；自绘开关触控区 44×24 偏小；`player_page` 无 `PopScope`，Android 返回手势直接退出 | 见左 |
| BUG-043 | 侧栏嵌套 Navigator 使用 `ValueKey(_selectedIndex)`，每次切 tab 整树重建，`HomeTab` 状态丢失并重新请求；`onLibrarySelected` 忽略 `libId` 参数 | `shell_screen.dart:142-151`、`:134-138` |
| BUG-044 | `_loadLibraryItems` 循环内不 await，并发 `copyWith` 存在覆盖竞态（后完成者以旧 map 为基底），`isLoading` 提前置 false；每库固定 15 条且无分页 | `home_provider.dart:85-89` |
| BUG-045 | `toggleMute` 恢复时写死 `1.0` 而非原音量 | `player_provider.dart:474` |
| BUG-046 | 交叉编译硬编码 `GOARCH=amd64`；非 Linux/Windows 直接 `FATAL_ERROR`（但 app 支持 macOS）；`DEPENDS` 仅列 `main.go`，改 `client.go` 等不触发重编 | `CMakeLists.txt:55`、`:28-36`、`:62` |
| BUG-047 | 桌面端 engine 动态库未打包：`BUILD_ENGINE` 默认 OFF 且无步骤将 `libaether_engine.so` 拷入 bundle/deb，而 `native_engine.dart:173-185` 仅探测 `engine/build/` 相对路径 → 安装版加载必失败（deb 却声明依赖 libmpv） | `CMakeLists.txt:16`、`:210` |

---

## 五、修复优先级建议

```
第一批（P0，核心功能与凭据安全）
  BUG-001 播放器不刷新        → 播放器当前基本不可用
  BUG-007 设置永不恢复        → 引擎/语言配置形同虚设
  BUG-002 令牌明文存储        → 凭据泄漏
  BUG-009 图片全挂            → 手机媒体库观感崩坏
  BUG-003/004 SSRF + 绑定 + CORS → 可被局域网与恶意网页利用
  BUG-005/006 C++ 类型 UB + FFI 回调 → 原生引擎崩溃面
  BUG-008 异常被吞            → 线上问题无从定位

第二批（P1，宣称特性不可用）
  BUG-010 搜索空壳  BUG-011 切换账户死循环  BUG-012 自动下一集
  BUG-014 自动登录不校验  BUG-020 代理截断流  BUG-022 进程挂死

第三批（P2/P3）
  体验打磨、性能、i18n、无障碍、构建脚本、测试补充
```
