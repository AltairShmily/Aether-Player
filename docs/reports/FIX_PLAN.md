# Aether Player — 修复方案报告

> 配套文档：`BUG_REPORT.md`（问题清单）、`OPTIMIZATION_REPORT.md`（功能与 UI 优化）
> 本文给出每类问题的**具体改法**、验证方式与提交划分。

---

## 一、验证环境与约束

| 子系统 | 本地可验证 | 手段 | 说明 |
|:--|:--|:--|:--|
| Flutter `app/` | ✅ | `flutter analyze` + `flutter test` | 本机 Flutter 3.47.0 / Dart 3.13.0 |
| Go `server/` | ⚠️ | `go vet` / `go build`（需工具链） | `go.mod` 要求 go 1.25.0 |
| C++ `engine/` | ❌ | 需 `libmpv-dev` + CMake | 本机无 mpv，依赖 CI |

**因此改动策略**：Flutter 侧可放开手改并本地验证；Go / C++ 侧采取**最小、自包含、语法保守**的改法，避免大范围重构，最终由 CI 的 `go vet` + `go build` + CMake 构建兜底验证。

**基线状态**：`flutter analyze` 对 `app/lib` 输出 `No issues found!`（已实测），说明现存问题全部是静态分析无法发现的语义缺陷 —— 修复后必须保持该基线不被打破。

---

## 二、P0 修复方案

### FIX-001 播放器状态监听（对应 BUG-001）

**改动文件**：`app/lib/screens/player_page.dart`

在控制器创建后（`:147` 附近）注册监听，`dispose` 中移除：

```dart
_playerController = controller;
controller.addListener(_onPlayerStateChanged);

void _onPlayerStateChanged(PlayerUiState _) {
  if (mounted) setState(() {});
}

@override
void dispose() {
  _playerController?.removeListener(_onPlayerStateChanged);
  // ... 原有清理
}
```

**为何不改成 Riverpod 托管**：`PlayerController` 需要按 `itemId` / `engine` 等运行时参数构造，且页面退出即销毁，手动管理 + 显式监听更贴合现状，改动面最小、风险最低。

**验证**：播放视频时进度条应逐秒推进、播放/暂停图标随状态切换、缓冲时出现指示。

---

### FIX-002 启动时恢复持久化设置（对应 BUG-007）

**改动文件**：`app/lib/main.dart`

在 `runApp` 之前注入一次性的启动初始化。由于 `load()` 挂在 provider notifier 上，而 `ProviderScope` 此时尚未构建，改为**在首屏之前用一个临时 `ProviderContainer` 完成加载**，或更简单可靠的方案：让 `main()` 直接调用底层 service 读取，再通过 override 注入初始值。

推荐做法（改动最小、语义最清晰）：

```dart
// main() 中，runApp 之前
final settings = SettingsService();
final savedEngine = await settings.getPlayerEngine();
final savedLocale = await settings.getLocale();

if (savedLocale != null) {
  LocaleSettings.setLocale(savedLocale);
} else {
  LocaleSettings.useDeviceLocale();
}
```

然后把 `savedEngine` 通过 `playerEngineProvider.overrideWith(...)` 注入初始状态，避免"先渲染默认值再跳变"的闪烁。

**验证**：设置页选"原生引擎" + "English" → 重启 → 两项均保持。

---

### FIX-003 令牌仅存于安全存储（对应 BUG-002）

**改动文件**：`app/lib/services/storage_service.dart`、`app/lib/providers/auth_provider.dart`

1. `StorageService.saveAuthData` 去掉 `token` 形参，删除 `prefs.setString(_tokenKey, ...)`。
2. 保留 `_tokenKey` 常量用于**清理历史遗留明文**：在 `clearAuthData()` 与一次性迁移逻辑中 `prefs.remove(_tokenKey)`。
3. `StorageService.getToken()` 删除（令牌读取统一走 `SecureStorageService`）。
4. `auth_provider.dart:71-76` 调用处同步去掉 `token:` 实参。

**注意**：`tryAutoLogin`（`:121`）已从 secure storage 读令牌，逻辑不变；需 grep 确认无其它调用方依赖 `StorageService.getToken()`。

**验证**：登录一次后检查 `shared_prefs` 中不再出现 `auth_token`；旧用户升级后首次启动应清除遗留明文键。

---

### FIX-004 SSRF 统一校验（对应 BUG-003）

**改动文件**：新建 `server/internal/security/ssrf.go`，修改 `proxy.go` / `library.go` / `playback.go` / `user.go` / `auth.go` / `emby/client.go`

**核心思路**：字符串黑名单不可靠，必须在**解析后的 IP 层**判断，并在**真正建连前**二次校验以防 DNS rebinding。

```go
package security

// IsPrivateIP 判断 IP 是否属于不应被代理访问的地址段
func IsPrivateIP(ip net.IP) bool {
    if ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() ||
       ip.IsLinkLocalMulticast() || ip.IsUnspecified() || ip.IsMulticast() {
        return true
    }
    return false
}

// ValidateServerURL 校验目标地址：scheme 白名单 + 解析后 IP 校验
func ValidateServerURL(raw string) (*url.URL, error) { ... }

// NewSafeTransport 返回带 DialContext 二次校验的 Transport，
// 并通过 CheckRedirect 拒绝跳转到私网地址
func NewSafeTransport() *http.Transport { ... }
```

**接入点**：所有从 `X-Emby-Server` 头或请求体 `server_url` 字段取地址的位置，统一先过 `ValidateServerURL`。

**权衡**：这会导致**局域网内的 Emby 服务器无法连接** —— 而家庭用户的 Emby 恰恰几乎都在局域网。因此该校验必须可配置：

```go
// 通过环境变量控制，默认允许私网（家用场景），显式关闭才严格拦截
allowPrivate := os.Getenv("AETHER_ALLOW_PRIVATE_NETWORK") != "false"
```

**这是本方案最重要的设计决策**：默认拦截私网会直接让产品对主要用户群不可用。因此默认放行私网、但**始终拦截**环回 / 链路本地 / 云元数据段（`169.254.169.254`），并把"严格模式"作为可选项与文档说明。

**验证**：`go vet ./...` + 单测覆盖十进制 IP、IPv6、重定向绕过用例。

---

### FIX-005 监听地址、CORS 与调用方鉴权（对应 BUG-004）

**改动文件**：`server/cmd/api/main.go`、`server/internal/middleware/middleware.go`、`app/lib/services/api_client.dart`、`app/lib/services/backend_service.dart`

1. **绑定地址**：`main.go:62` 改为 `http.ListenAndServe("127.0.0.1:"+port, h)`，与 `mobile.go:47` 及架构文档一致。可用 `BIND_ADDR` 环境变量覆盖（供容器/远程场景显式放开）。
2. **CORS**：`middleware.go` 默认不再 `*`；未设置 `CORS_ALLOW_ORIGIN` 时不输出该头（本地代理与 Flutter 客户端同源，无需 CORS）。
3. **鉴权**：进程启动时生成随机 token，写入 Flutter 端可读的位置（子进程启动参数或 stdout 首行），中间件校验 `Authorization: Bearer`。
4. **超时防护**：改用 `http.Server{ReadHeaderTimeout: 10s}`，防 Slowloris。

**分步实施建议**：第 1、2、4 项风险低、收益高，本轮直接做；第 3 项（鉴权握手）涉及 Flutter 与 Go 双侧协议改动，单独一轮并配合集成测试。

---

### FIX-006 C++ 类型与属性名修正（对应 BUG-005、BUG-023）

**改动文件**：`engine/src/core/playback_engine.cpp`

```cpp
// :132 —— int → int64_t
int64_t mpv_id = _audioTracks[index].index + 1;
mpv_set_property(_handle, "aid", MPV_FORMAT_INT64, &mpv_id);

// :148 —— 同上
int64_t mpv_id = _subtitleTracks[index].index + 1;
mpv_set_property(_handle, "sid", MPV_FORMAT_INT64, &mpv_id);

// :39 —— 属性名修正
mpv_observe_property(_handle, 0, "cache-buffering-state", MPV_FORMAT_DOUBLE);

// :267 —— 事件分支同步改名，并按 double 解析
```

注意 `cache-buffering-state` 是 **double（0-100）** 而非 flag，`:267` 的判断需同步从 `MPV_FORMAT_FLAG` 改为 `MPV_FORMAT_DOUBLE`，并定义缓冲阈值（如 `< 100` 视为缓冲中）。

---

### FIX-007 FFI 回调改用 `NativeCallable.listener`（对应 BUG-006）

**改动文件**：`app/lib/services/native_engine.dart`

```dart
// 旧：Pointer.fromFunction（同步、要求同 isolate 线程）
// 新：NativeCallable.listener（异步投递，跨线程安全）
final callable = NativeCallable<void>.listener(_onNativeEvent);
_engine_set_callback(callable.nativeFunction);

@override
void dispose() {
  _engine_unregister_callback();   // 1. 先注销 C 侧回调
  _engine_destroy(_handle);        // 2. 再销毁引擎
  callable.close();                // 3. 最后关闭 callable
  _controller.close();             // 4. 关闭流
}
```

同时移除 `:260` 的全局静态 `_instance`，改为每实例持有 `NativeCallable`。

**C++ 侧配合**：回调签名需与 `NativeCallable.listener` 兼容（`Void Function(Pointer<Void>)` 形式，事件数据通过指针或消息传递）。此项改动跨 Dart/C++ 两侧且无法本地编译验证，**风险最高**，建议单独一轮提交，并在无 mpv 环境下至少保证 `flutter analyze` 通过 + 代码审查。

---

### FIX-008 恢复错误上报链路（对应 BUG-008）

**改动文件**：`app/lib/main.dart`

```dart
FlutterError.onError = (details) {
  FlutterError.presentError(details);        // 恢复：debug 红屏可见
  _logError(details.exception, details.stack); // release：落盘
};
```

`runZonedGuarded` 的 onError 同样落盘而非仅 `debugPrint`，并保留 stackTrace。日志文件写入 `getApplicationSupportDirectory()`，设置页提供"导出错误日志"入口（配合 FIX-014 的可诊断性目标）。

---

### FIX-009 图片代理地址统一（对应 BUG-009）

**改动文件**：`app/lib/screens/phone_library_screen.dart:288`、`:478`

```dart
// 改为
'${ApiClient.proxyBaseUrl}/api/images/${item.id}/Primary?maxWidth=300'
```

`:322` 的 `X-Emby-Server` 头保持不变，代理据此转发。同时建议全站收敛为 `ApiClient.getImageUrl()`（该方法已存在于 `api_client.dart:221` 但零引用），消除三处重复拼接。

---

## 三、P1 修复方案

| 编号 | 对应 Bug | 改法要点 | 改动文件 |
|:--|:--|:--|:--|
| FIX-010 | BUG-010 | `shell_screen` 传入 `onSubmitted` 实际调 `ApiClient.search`；`_SearchDialog` 渲染真实结果列表（已有 `search()` 接口可直接用） | `shell_screen.dart`、`home_tab.dart` |
| FIX-011 | BUG-011 | "切换账户"先 `await ref.read(authProvider.notifier).logout()` 再跳转，与 `home_tab.dart:420-427` 对齐 | `settings_tab.dart:174-179` |
| FIX-012 | BUG-012 | 3 个调用点补传 `seriesId`/`seasonId`/`episodeIndex`；`_nextEpisodeId` 改为**播放开始时**即预取下一集 ID，使"下一集"按钮可点 | `episode_detail_screen.dart:126`、`media_detail_screen.dart:255,511`、`player_page.dart` |
| FIX-013 | BUG-013 | `_selectedSubtitleIndex` 默认值由 `0` 改为 `null`；`player_page.dart:166` 判断与音轨统一为 `!= null && >= 0` | `episode_detail_screen.dart:131`、`player_page.dart` |
| FIX-014 | BUG-014 | `tryAutoLogin` 拿到令牌后调 `/System/Info` 验证；401 → 清凭据 + 返回 false，让 UI 回登录页并提示"登录已过期"；`home_provider.dart:117` 的 `catch (_)` 改为记录错误到 state | `auth_provider.dart:120-138`、`home_provider.dart` |
| FIX-015 | BUG-015 | `error: error ?? this.error`；需要主动清空时显式传哨兵值或新增 `clearError()` 方法 | `auth_provider.dart:33`、`home_provider.dart:37` |
| FIX-016 | BUG-016 | 所有 `await` 之后的 `setState` 前置 `if (!mounted) return;` | `login_screen.dart:30-34` 等 |
| FIX-017 | BUG-017 | 用带索引的 `asMap().entries` 遍历；无编号集使用 `-1 - i` 负数键避免与真实 `indexNumber` 冲突 | `episode_utils.dart:12` |
| FIX-018 | BUG-018 | `pubspec.yaml` 补 `media_kit_libs_android`（或按实际支持平台补全），并核对 `MediaKit.ensureInitialized()` 调用时机 | `app/pubspec.yaml` |
| FIX-019 | BUG-019 | 分离缓存 `_directPlayUrl` / `_transcodeUrl`，切换时按目标画质取对应字段 | `player_provider.dart:405` |
| FIX-020 | BUG-020 | 包级共享 `http.Client`（去掉整体 `Timeout`，改用 `Transport.ResponseHeaderTimeout`）；流式响应用 `http.Flusher` 刷新；`io.Copy` 错误记录日志 | `proxy.go:101,123`、`library.go:142` |
| FIX-021 | BUG-021 | 全部改用 `url.Values{}.Encode()` 构造查询串 | `emby/client.go:279-289,381-382` |
| FIX-022 | BUG-022 | `backend_service` 中 listen 子进程 stdout/stderr 并转发到 Dart 日志（带行数上限防泄漏）；`_emergencyStop` 改为同步 `Process.killSync` + 最终 `exit()`；信号处理器注册加去重标志 | `backend_service.dart:107-117,231-246` |
| FIX-023 | BUG-036 | `deviceID` 做引号转义与字符白名单过滤（仅允许 `[A-Za-z0-9._-]`）后再拼入 `X-Emby-Authorization` | `proxy.go:98` |
| FIX-024 | BUG-037 | 改用 `http.Server` + `signal.NotifyContext` 实现 graceful shutdown，设置 `ReadHeaderTimeout` | `cmd/api/main.go:62` |

---

## 四、P2 / P3 修复方案（摘要）

| 编号 | 改法要点 |
|:--|:--|
| FIX-025 | `player_page.dispose` 补 `_autoPlayTimer?.cancel()`；`reportStopped()` 改为 `await` 后再 dispose（用 `WidgetsBinding.instance.addPostFrameCallback` 或将上报移入异步安全路径） |
| FIX-026 | Slider 增加 `onChangeStart` / `onChangeEnd`：拖动期间只更新本地 `_dragValue`，松手才真正 `seek`；启用已定义但未用的 `PlayerUiState.isSeeking` |
| FIX-027 | `_StarPainter` 星星列表改为构造时一次性生成并复用（`final List<Star> _stars`），painter 加 `shouldRepaint` 判断；外层包 `RepaintBoundary` |
| FIX-028 | 死配置项二选一：接线到实际消费方（如硬件加速 → `MpvEngine` 的 `hwdec` 参数、字幕大小 → `sub-font-size`），或在 UI 上明确标注"实验性/暂未生效"；统一复用 `settingsServiceProvider` 而非新建实例 |
| FIX-029 | 删除零引用死代码（`VideoOsd`、`MiniPlayBar`、`AudioPlayerPage` 等）或补齐入口；`getImageUrl` 收敛为唯一图片 URL 构造点 |
| FIX-030 | i18n 补齐：把硬编码中文迁入 slang 的 `strings.i18n.json`，`dart run slang` 重新生成 |
| FIX-031 | 错误提示改为用户可读文案 + 本地化，技术细节写日志；消灭 `catch (_)` 空吞 |
| FIX-032 | 模型解析：`media_models.dart:186` 删除重复表达式；`auth_models.dart` / `saved_server.dart` 全部改为安全 cast（`as String? ?? ''`），`getSavedServers` 外层加 try/catch 容错单条脏数据 |
| FIX-033 | 补单测：`episode_utils`（含键冲突回归用例）、`playback_strategy`、各 provider 的状态转换；目标从 1 个用例提升到覆盖核心纯逻辑 |
| FIX-034 | `CMakeLists.txt:200-215` 改用 `file(GENERATE OUTPUT ... CONTENT ...)` 生成 `DEBIAN/control`，或 `sh -c 'echo ... > control'` |
| FIX-035 | `ToggleFavorite` 参数改名为 `currentlyFavorite` 明确语义，或反转实现与调用方约定一致，并补注释 |
| FIX-036 | `client.go` 的 stream URL 改为经本地代理，令牌走请求头而非 query（`api_key=`），避免进入访问日志 |
| FIX-037 | `mobile.go` 与 `main.go` 的路由表抽取为共享 `buildMux()`，消除双份维护 |
| FIX-038 | `CMakeLists.txt:55` 的 `GOARCH` 改为按 `CMAKE_SYSTEM_PROCESSOR` 推导；`:62` `DEPENDS` 扩展为 `GLOB` 全部 `.go` 文件；`:28-36` 增加 macOS 分支 |
| FIX-039 | 打开 `BUILD_ENGINE` 时把 `libaether_engine.so` 拷入 bundle 与 deb；修正 deb 依赖声明与实际打包内容一致 |
| FIX-040 | 图片改用 `cached_network_image`（需代理支持 query token）或至少设置 `cacheWidth`；`shell_screen` 嵌套 Navigator 改用 `IndexedStack` 保留各 tab 状态；`toggleMute` 恢复原音量 |

---

## 五、提交划分（Conventional Commits，中文）

按"一个提交解决一类问题、可独立回滚"的原则划分：

| # | Commit message | 内容 |
|:--|:--|:--|
| 1 | `🐛 fix: 修复播放器 UI 不随播放状态刷新的问题` | FIX-001 |
| 2 | `🐛 fix: 启动时恢复播放引擎与语言设置` | FIX-002 |
| 3 | `🔒 fix: Emby 令牌仅存于安全存储，移除明文副本` | FIX-003 |
| 4 | `🐛 fix: 修正手机媒体库图片代理地址错误` | FIX-009 |
| 5 | `🐛 fix: 恢复全局异常上报链路，避免错误被静默吞掉` | FIX-008 |
| 6 | `🐛 fix: 修正 copyWith 丢失 error 与 async gap 后 setState` | FIX-015、FIX-016 |
| 7 | `🐛 fix: 修复切换账户死循环与字幕强制选中` | FIX-011、FIX-013 |
| 8 | `🐛 fix: 自动登录校验令牌有效性并暴露加载错误` | FIX-014 |
| 9 | `✨ feat: 实现媒体库搜索功能` | FIX-010 |
| 10 | `✨ feat: 打通自动播放下一集链路` | FIX-012 |
| 11 | `🐛 fix: 修正剧集合并键冲突与画质回退地址` | FIX-017、FIX-019 |
| 12 | `🎨 style: 播放器进度条拖拽与星空动画性能优化` | FIX-026、FIX-027 |
| 13 | `🐛 fix: 模型解析容错与错误提示本地化` | FIX-031、FIX-032 |
| 14 | `🔒 fix: Go 代理统一 SSRF 校验并收敛监听地址与 CORS` | FIX-004、FIX-005 |
| 15 | `🐛 fix: Go 代理复用连接、取消流截断超时、转义设备 ID` | FIX-020、FIX-023 |
| 16 | `🐛 fix: Emby 客户端查询参数 URL 编码` | FIX-021 |
| 17 | `✨ feat: Go 服务支持优雅关闭与请求头超时` | FIX-024 |
| 18 | `🐛 fix: 修正 C++ 引擎 mpv 属性类型与缓冲属性名` | FIX-006 |
| 19 | `🐛 fix: 后端进程管道消费与退出清理` | FIX-022 |
| 20 | `🔧 chore: 修复 CMake 打包与交叉编译配置` | FIX-034、FIX-038 |
| 21 | `📝 docs: 更新 README 与新增代码审查报告` | 文档 |
| 22 | `✅ test: 补充核心逻辑单元测试` | FIX-033 |

**风险分级**：提交 1-13、18（Flutter + C++ 小改）风险低；提交 14-17、19-20（Go + 构建）无本地编译器，需重点依赖 CI 验证；FIX-007（FFI 回调重构）风险最高，若时间不足应单独排期而非混入本轮。

---

## 六、不在本轮修复范围（需单独决策）

| 项 | 原因 |
|:--|:--|
| FIX-005 第 3 步（Bearer 鉴权握手） | 跨 Dart/Go 协议改动，需集成测试环境 |
| FIX-007（FFI `NativeCallable` 重构） | 无法本地编译验证 mpv 侧行为，改动风险高 |
| BUG-033（Android AAR 缺失） | 属 CI 构建流程设计，需确认是否改为仓库内提交 AAR 或文档说明 |
| BUG-030（i18n 全量补齐） | 工作量大，涉及全部界面文案，宜独立专项 |
| BUG-038（令牌进 URL） | 需 Emby 侧确认代理转发 stream 的可行性，涉及播放链路 |
