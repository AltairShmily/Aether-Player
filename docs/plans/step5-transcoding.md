# Step 5：转码服务与高级功能 — 实施计划

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** 实现智能播放策略（Direct Play / Transcode 自动选择）、画质切换 UI、带宽自适应，让播放器能应对不同网络和编码环境。

**Architecture:** 
- Go 后端增强 DeviceProfile，返回完整 MediaSource（含 TranscodingUrl），新增带宽检测端点
- Flutter 端新增播放策略引擎，根据 MediaSource 信息自动选择 Direct Play 或转码
- UI 新增画质选择面板，用户可手动覆盖自动策略

**Tech Stack:** Go (net/http, encoding/json), Flutter (Riverpod, media_kit/libmpv), Emby API

---

## 现状分析

### 已有基础
| 组件 | 状态 | 说明 |
|------|------|------|
| Go `GetPlaybackInfo` | ✅ | 调用 Emby `POST /Items/{id}/PlaybackInfo`，发送 DeviceProfile |
| Go `DeviceProfile` | ✅ | 已配置 DirectPlay + Transcode 编解码器支持 |
| Go `MediaSource` 结构体 | ⚠️ | 缺少 `DirectStreamUrl`、`TranscodingUrl`、`SupportsDirectPlay` 等字段 |
| Flutter `playback_models.dart` | ✅ | 已有 `PlaybackInfo` + `MediaSourceInfo`（含 directStreamUrl/transcodeUrl），**但未使用** |
| Flutter `media_models.dart` | ✅ | 简单版 `MediaSource`（当前使用中） |
| Flutter `PlayerController` | ⚠️ | 使用简单模型，硬编码 Direct Play |
| Flutter `player_page.dart` | ⚠️ | 无画质选择 UI |

### 需要新增
1. Go: `MediaSource` 结构体补全 Emby 返回的字段
2. Go: 带码率参数的转码 URL 构造
3. Go: 带宽探测端点
4. Flutter: `PlaybackStrategy` 播放策略引擎
5. Flutter: `PlayerController` 使用完整 PlaybackInfo + 策略引擎
6. Flutter: 画质选择 UI 面板
7. Flutter: 播放模式标识显示

---

### Task 1: Go — 补全 MediaSource 结构体字段

**Objective:** 让 Go 后端的 `MediaSource` 能完整携带 Emby 返回的 Direct/Transcode 信息。

**Files:**
- Modify: `server/internal/emby/client.go` — `MediaSource` 结构体

**Step 1:** 在 `emby/client.go` 的 `MediaSource` 结构体中添加字段：

```go
type MediaSource struct {
    ID              string        `json:"Id"`
    Container       string        `json:"Container"`
    Size            int64         `json:"Size"`
    Bitrate         int64         `json:"Bitrate"`
    MediaStreams    []MediaStream `json:"MediaStreams"`
    // 已有
    DirectStreamUrl string        `json:"DirectStreamUrl,omitempty"`
    TranscodingUrl  string        `json:"TranscodingUrl,omitempty"`
    // 新增 — Emby PlaybackInfo 返回的决策字段
    Path            string        `json:"Path,omitempty"`
    Name            string        `json:"Name,omitempty"`
    IsRemote        bool          `json:"IsRemote"`
    SupportsDirectPlay   bool     `json:"SupportsDirectPlay"`
    SupportsDirectStream bool     `json:"SupportsDirectStream"`
    SupportsTranscoding  bool     `json:"SupportsTranscoding"`
}
```

**Step 2:** 确认 `GetPlaybackInfo` 的响应 JSON 能正确反序列化这些字段（Emby API 返回时字段名首字母大写）。

**Step 3:** 验证：启动 Go 后端，`curl localhost:19800/api/playback/{itemId}/info`，确认返回含 `SupportsDirectPlay` 等新字段。

**Step 4:** Commit: `✨ feat: 补全 MediaSource 结构体支持 Transcode 字段`

---

### Task 2: Go — 带码率参数的转码 URL 构造

**Objective:** 支持客户端指定目标码率/分辨率，构造 Emby 转码 URL。

**Files:**
- Modify: `server/internal/emby/client.go` — 新增 `GetTranscodeStreamURL`
- Modify: `server/internal/handler/playback.go` — 新增 handler
- Modify: `server/cmd/api/main.go` — 注册路由

**Step 1:** 在 `client.go` 添加：

```go
// GetTranscodeStreamURL 构造带码率限制的转码 URL
func (c *Client) GetTranscodeStreamURL(serverURL, token, itemID string, maxBitrate, maxHeight int) string {
    url := fmt.Sprintf("%s/Videos/%s/stream?api_key=%s&VideoCodec=h264&AudioCodec=aac&MaxStreamingBitrate=%d",
        serverURL, itemID, token, maxBitrate)
    if maxHeight > 0 {
        url += fmt.Sprintf("&MaxHeight=%d", maxHeight)
    }
    return url
}
```

**Step 2:** 在 `playback.go` 添加 handler：

```go
func GetTranscodeStream(client *emby.Client) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        itemID := mux.Vars(r)["itemId"]
        maxBitrate, _ := strconv.Atoi(r.URL.Query().Get("maxBitrate"))
        maxHeight, _ := strconv.Atoi(r.URL.Query().Get("maxHeight"))
        if maxBitrate <= 0 { maxBitrate = 20_000_000 }

        serverURL := r.Header.Get("X-Emby-Server")
        token := r.Header.Get("X-Emby-Token")
        streamURL := client.GetTranscodeStreamURL(serverURL, token, itemID, maxBitrate, maxHeight)

        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]string{"streamUrl": streamURL})
    }
}
```

**Step 3:** 在 `main.go` 注册路由：
```go
playbackRouter.HandleFunc("/{itemId}/transcode", handler.GetTranscodeStream(embyClient)).Methods("GET")
```

**Step 4:** 验证：`curl 'localhost:19800/api/playback/{itemId}/transcode?maxBitrate=5000000&maxHeight=720'`

**Step 5:** Commit: `✨ feat: 添加转码 URL 构造端点`

---

### Task 3: Flutter — 补全 MediaSourceInfo 字段

**Objective:** 让 Flutter 的 `MediaSourceInfo` 能解析 Emby 返回的 `SupportsDirectPlay` 等字段。

**Files:**
- Modify: `app/lib/models/playback_models.dart` — `MediaSourceInfo` 类

**Step 1:** 在 `MediaSourceInfo` 添加字段和解析：

```dart
class MediaSourceInfo {
  // ... 已有字段 ...
  final bool supportsDirectPlay;
  final bool supportsDirectStream;
  final bool supportsTranscoding;

  const MediaSourceInfo({
    // ... 已有参数 ...
    this.supportsDirectPlay = true,   // 默认 true（兼容旧数据）
    this.supportsDirectStream = true,
    this.supportsTranscoding = false,
  });

  factory MediaSourceInfo.fromJson(Map<String, dynamic> json) {
    return MediaSourceInfo(
      // ... 已有解析 ...
      supportsDirectPlay: json['SupportsDirectPlay'] as bool? ?? true,
      supportsDirectStream: json['SupportsDirectStream'] as bool? ?? true,
      supportsTranscoding: json['SupportsTranscoding'] as bool? ?? false,
    );
  }
}
```

**Step 2:** 验证：`flutter analyze` 无新增错误。

**Step 3:** Commit: `✨ feat: MediaSourceInfo 支持 Transcode 决策字段`

---

### Task 4: Flutter — 新增 PlaybackStrategy 播放策略引擎

**Objective:** 封装播放策略逻辑 — 自动判断 Direct Play / Transcode。

**Files:**
- Create: `app/lib/services/playback_strategy.dart`

**Step 1:** 创建文件（完整代码见上文 Task 4 原版）。关键类：
- `PlayMode` 枚举：`directPlay`, `directStream`, `transcode`
- `PlaybackDecision` 数据类：mode + streamUrl + reason
- `PlaybackStrategy.auto(MediaSourceInfo)` — 自动决策
- `PlaybackStrategy.forceTranscode(MediaSourceInfo)` — 强制转码

**Step 2:** 验证：import 正确，无语法错误。

**Step 3:** Commit: `✨ feat: PlaybackStrategy 播放策略引擎`

---

### Task 5: Flutter — PlayerController 集成策略引擎

**Objective:** 让 PlayerController 使用 PlaybackStrategy 选择播放 URL，并记录当前播放模式。

**Files:**
- Modify: `app/lib/providers/player_provider.dart`
- Modify: `app/lib/services/api_client.dart` — 新增 `getPlaybackInfoFull`

**Step 1:** 在 `api_client.dart` 新增：
```dart
Future<PlaybackInfo> getPlaybackInfoFull(String itemId) async {
    final resp = await _get('/api/playback/$itemId/info');
    return PlaybackInfo.fromJson(resp);
}
```

**Step 2:** 在 `PlayerUiState` 添加：
```dart
final PlayMode? currentPlayMode;
final String? playModeReason;
```

**Step 3:** 在 `loadAndPlay()` 中：
- 调用 `getPlaybackInfoFull` 获取 `PlaybackInfo`
- 取第一个 `mediaSource`
- 调用 `PlaybackStrategy.auto(source)` 获取决策
- 用 `decision.streamUrl` 打开引擎
- 更新 state 中的 `currentPlayMode`

**Step 4:** 验证：播放视频，日志输出播放模式。

**Step 5:** Commit: `✨ feat: PlayerController 集成 PlaybackStrategy`

---

### Task 6: Flutter — 画质选择 UI 面板

**Objective:** 在播放页添加画质选择弹出面板。

**Files:**
- Create: `app/lib/widgets/quality_selector.dart`
- Modify: `app/lib/screens/player_page.dart` — 添加画质按钮和面板

**Step 1:** 创建 `quality_selector.dart`（完整代码见上文 Task 6 原版）。
- `QualityOption` 数据类
- `QualitySelector` widget — 底部弹出面板
- `QualitySelector.fromMediaSource()` — 根据 MediaSource 生成选项

**Step 2:** 在 `player_page.dart` 控制栏添加画质按钮（HD 图标）。

**Step 3:** 在 `PlayerController` 添加 `switchQuality(QualityOption)` 方法：
- 保存当前 position
- 如果 transcode：调用 `api.getTranscodeStreamUrl(itemId, maxBitrate, maxHeight)`
- 如果 directPlay：使用 `mediaSource.directStreamUrl`
- engine.stop() → engine.open(newUrl) → engine.seek(savedPosition)

**Step 4:** 验证：播放中切换画质，从原位置继续播放。

**Step 5:** Commit: `✨ feat: 画质选择 UI 面板`

---

### Task 7: Flutter — 播放模式标识 + 测试

**Objective:** 控制栏显示当前播放模式标签，端到端测试。

**Files:**
- Modify: `app/lib/screens/player_page.dart` — 添加模式标签

**Step 1:** 在控制栏顶部添加小标签（绿色 = Direct Play，橙色 = Transcode）。

**Step 2:** 端到端测试：
- Direct Play：播放 H.264 MP4 → 标签 "Direct Play"
- 手动 720p → 标签 "Transcode"，画质降低
- 切换回原始 → 恢复 Direct Play
- 进度上报正常

**Step 3:** 更新 `docs/Aether_开发计划书.md` 标记 Step 5 完成。

**Step 4:** Commit: `✨ feat: 播放模式标识 + Step 5 完成`
