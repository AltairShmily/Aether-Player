# Step 3: 视频播放（media_kit 集成）

## Goal

在 Flutter 端集成 media_kit 播放引擎，实现点击媒体项后进入播放页，支持基础播放控制（播放/暂停/进度拖拽/倍速/全屏）、音轨/字幕切换、播放进度上报。

## Current Context

- **Go 后端**：播放相关 API 已全部就绪（`/api/playback/{id}/info`、`/api/playback/{id}/stream`、`/api/playback/started|progress|stopped`）
- **Flutter 端**：无播放器依赖，`media_detail_screen.dart` 和 `episode_detail_screen.dart` 的播放按钮 TODO 空实现
- **Go 路由**：`main.go` 中 `playbackRouter` 已注册完整路由
- **Emby 认证**：播放 URL 需携带 `api_key` 参数（Go 后端已处理）

## Implementation Plan

### Phase 1: 依赖安装 + 播放引擎抽象层

1. **安装 media_kit 依赖**（`app/pubspec.yaml`）
   - `media_kit` / `media_kit_video` / `media_kit_libs_linux` / `media_kit_libs_windows` / `media_kit_libs_macos`
   - Flutter 原生 `media_kit:video` 用于 Video widget

2. **创建播放引擎抽象层**（`lib/services/player_engine.dart`）
   - 定义 `PlayerEngine` 抽象接口：play / pause / seek / setAudioTrack / setSubtitleTrack / dispose
   - 定义 `PlayerState` 状态类：position / duration / isPlaying / isBuffering / playbackRate / audioTracks / subtitleTracks

3. **实现 MpvEngine**（`lib/services/mpv_engine.dart`）
   - 基于 media_kit `Player` 类实现 `PlayerEngine` 接口
   - 监听 media_kit 事件流，同步状态到 `PlayerState`
   - 支持设置自定义 HTTP headers（Emby 认证头）

### Phase 2: 播放控制器 (Riverpod Provider)

4. **创建 PlayerController**（`lib/providers/player_provider.dart`）
   - 基于 `StateNotifier<PlayerState>`
   - 封装 PlayerEngine 实例管理
   - 播放/暂停/seek/倍速切换等操作方法
   - 播放进度上报定时器（每 10 秒）
   - 播放开始/结束事件上报

5. **创建播放数据模型**（`lib/models/playback_models.dart`）
   - `PlaybackInfo`：mediaSources / playSessionId
   - `StreamInfo`：streamUrl / directPlayURL / transcodeURL
   - `AudioTrack` / `SubtitleTrack`

### Phase 3: 播放页 UI

6. **创建播放页**（`lib/screens/player_page.dart`）
   - 全屏播放，深色背景
   - 视频渲染区域（`Video` widget from media_kit）
   - 自定义控制栏：播放/暂停按钮、进度条（可拖拽）、时间标签、全屏按钮
   - 顶部返回按钮 + 标题
   - 底部音轨/字幕切换按钮

7. **实现控制栏 UI 组件**（`lib/widgets/player_controls.dart`）
   - 进度条：支持拖拽 seek，显示当前时间/总时长
   - 播放/暂停按钮（居中大按钮 + 底部小按钮）
   - 倍速切换（0.5x / 1x / 1.5x / 2x）
   - 全屏切换

8. **实现音轨/字幕选择弹窗**（`lib/widgets/track_selector.dart`）
   - BottomSheet 或 Dialog
   - 显示可用音轨列表（语言 + 编解码器）
   - 显示可用字幕列表（含"关闭字幕"选项）

### Phase 4: 集成到现有页面

9. **媒体详情页播放按钮**（修改 `media_detail_screen.dart`）
   - 点击"播放"按钮 → 调用 API 获取播放信息 → 跳转 PlayerPage

10. **剧集详情页播放按钮**（修改 `episode_detail_screen.dart`）
    - 同上逻辑

11. **续播功能**
    - 如果 episode 有 userData.playbackPositionTicks > 0，显示"从 X:XX 继续"按钮
    - 跳转后 seek 到断点位置

### Phase 5: 进度上报

12. **进度上报逻辑**（在 PlayerController 中实现）
    - 播放开始时 POST `/api/playback/started`
    - 播放期间每 10 秒 POST `/api/playback/progress`
    - 播放暂停/停止时 POST `/api/playback/stopped`

## Files to Create

```
app/lib/
├── models/playback_models.dart          # 播放相关数据模型
├── services/player_engine.dart           # PlayerEngine 抽象接口
├── services/mpv_engine.dart              # media_kit 实现
├── providers/player_provider.dart        # PlayerController (StateNotifier)
├── screens/player_page.dart              # 播放页主页面
├── widgets/player_controls.dart          # 自定义控制栏
└── widgets/track_selector.dart           # 音轨/字幕选择器
```

## Files to Modify

```
app/pubspec.yaml                         # 添加 media_kit 依赖
app/lib/screens/media_detail_screen.dart  # 播放按钮跳转
app/lib/screens/episode_detail_screen.dart # 播放按钮跳转
app/lib/screens/series_detail_screen.dart  # 剧集播放跳转（如需要）
```

## Validation

1. `cd app && flutter pub get` — 依赖安装成功
2. `dart analyze` — 0 errors
3. 启动 Go 后端 + Flutter → 播放电影/剧集 → 控制栏可操作
4. 音轨/字幕切换正常
5. 播放进度上报到 Emby（可在 Emby 仪表盘验证）
6. 退出后重新进入显示"继续播放"

## Risks

- media_kit 在 Linux 上需要 libmpv 系统库（`sudo dnf install mpv-devel`）
- 首次编译可能需要较长时间
- HLS 转码流可能需要额外配置 ffmpeg 路径
