import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/mpv_engine.dart';

// ══════════════════════════════════════════════════════════════════
//  播放器页面 — 全屏视频播放
// ══════════════════════════════════════════════════════════════════

/// 全屏视频播放页面
///
/// 功能：
/// - 基于 media_kit 的视频渲染
/// - 自定义覆盖控制面板（自动隐藏）
/// - 双击快进 / 快退
/// - 单击切换控制面板
/// - 横屏锁定
/// - Wakelock（屏幕常亮）
/// - Emby 播放进度上报
class PlayerPage extends ConsumerStatefulWidget {
  /// 媒体项 ID
  final String itemId;

  /// 媒体标题（显示在控制栏顶部）
  final String title;

  /// 起始播放位置（毫秒），用于恢复播放
  final int startAtMs;

  const PlayerPage({
    super.key,
    required this.itemId,
    required this.title,
    this.startAtMs = 0,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  // ── 本地 UI 状态 ──────────────────────────────────────────────
  VideoController? _videoController;
  bool _isInitialized = false;

  // 双击检测
  DateTime? _lastTapTime;
  String? _seekIndicatorText; // "10s >>" 或 "<< 10s"
  Timer? _seekIndicatorTimer;

  // 左/右侧双击 seek 的累计秒数
  int _leftSeekAccum = 0;
  int _rightSeekAccum = 0;
  Timer? _seekAccumResetTimer;

  @override
  void initState() {
    super.initState();

    // 进入全屏 + 横屏 + 隐藏系统 UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 开启屏幕常亮
    WakelockPlus.enable();

    // 初始化播放
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlayer();
    });
  }

  /// 初始化播放器并开始播放
  Future<void> _initPlayer() async {
    final auth = ref.read(authProvider).authResult;
    if (auth == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final serverUrl =
        await ref.read(storageServiceProvider).getServerUrl();
    if (serverUrl == null || !mounted) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // 创建控制器
    final controller = PlayerController(
      serverUrl: serverUrl,
      token: auth.token,
      userId: auth.user.id,
    );

    // 获取引擎的 VideoController
    final engine = controller.engine as MpvEngine;
    _videoController = engine.videoController;

    // 保存 controller 到 state 以便后续访问
    _playerController = controller;

    if (mounted) {
      setState(() => _isInitialized = true);

      // 开始播放
      controller.loadAndPlay(
        widget.itemId,
        title: widget.title,
        startAtMs: widget.startAtMs,
      );
    }
  }

  // PlayerController 的引用（非 Riverpod 管理，手动创建）
  PlayerController? _playerController;

  @override
  void dispose() {
    // 恢复系统 UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);

    // 关闭屏幕常亮
    WakelockPlus.disable();

    // 上报播放停止
    _playerController?.reportStopped();

    // 释放控制器
    _playerController?.dispose();

    _seekIndicatorTimer?.cancel();
    _seekAccumResetTimer?.cancel();

    super.dispose();
  }

  // ── 手势处理 ──────────────────────────────────────────────

  /// 处理屏幕点击（单击 / 双击）
  void _onScreenTap(TapUpDetails details) {
    final now = DateTime.now();
    final dx = details.globalPosition.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = dx < screenWidth / 3;
    final isRightSide = dx > screenWidth * 2 / 3;

    // 检测双击
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      // 双击事件
      _lastTapTime = null;

      if (isLeftSide) {
        _handleDoubleTapBackward();
      } else if (isRightSide) {
        _handleDoubleTapForward();
      } else {
        // 中间双击 = 播放/暂停
        _playerController?.togglePlayPause();
      }
      return;
    }

    // 延迟判断是否为单击
    _lastTapTime = now;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastTapTime == now && mounted) {
        // 这是单击
        _playerController?.toggleControls();
      }
    });
  }

  /// 双击快退
  void _handleDoubleTapBackward() {
    _rightSeekAccum = 0;
    _leftSeekAccum += 10;
    _playerController?.seekBackward(10);
    _showSeekIndicator('<< $_leftSeekAccum');
    _resetSeekAccumTimer();
  }

  /// 双击快进
  void _handleDoubleTapForward() {
    _leftSeekAccum = 0;
    _rightSeekAccum += 10;
    _playerController?.seekForward(10);
    _showSeekIndicator('$_rightSeekAccum >>');
    _resetSeekAccumTimer();
  }

  /// 显示 seek 指示器
  void _showSeekIndicator(String text) {
    setState(() => _seekIndicatorText = text);
    _seekIndicatorTimer?.cancel();
    _seekIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _seekIndicatorText = null);
    });
  }

  /// 重置 seek 累计计时器
  void _resetSeekAccumTimer() {
    _seekAccumResetTimer?.cancel();
    _seekAccumResetTimer = Timer(const Duration(seconds: 1), () {
      _leftSeekAccum = 0;
      _rightSeekAccum = 0;
    });
  }

  // ── 构建 UI ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = _playerController?.currentState;

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 视频渲染 ──
          if (_isInitialized && _videoController != null)
            Center(
              child: Video(
                controller: _videoController!,
                controls: NoVideoControls, // 使用自定义控制面板
              ),
            ),

          // ── 加载中指示器 ──
          if (!_isInitialized || (state != null && state.isBuffering))
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.celestialCyan,
                strokeWidth: 2,
              ),
            ),

          // ── 点击区域（手势检测） ──
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _onScreenTap,
              child: Container(color: Colors.transparent),
            ),
          ),

          // ── Seek 指示器 ──
          if (_seekIndicatorText != null)
            Center(
              child: AnimatedOpacity(
                opacity: _seekIndicatorText != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _seekIndicatorText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ),
            ),

          // ── 控制面板覆盖 ──
          if (state != null && state.showControls)
            _PlayerControlsOverlay(
              state: state,
              onBack: () => Navigator.of(context).pop(),
              onPlayPause: () => _playerController?.togglePlayPause(),
              onSeek: (progress) =>
                  _playerController?.seekToProgress(progress),
              onSeekForward: () => _playerController?.seekForward(),
              onSeekBackward: () => _playerController?.seekBackward(),
              onVolumeChanged: (v) => _playerController?.setVolume(v),
              onMuteToggle: () => _playerController?.toggleMute(),
              onSpeedChanged: (s) => _playerController?.setPlaybackSpeed(s),
              onAudioTrackSelected: (i) =>
                  _playerController?.selectAudioTrack(i),
              onSubtitleTrackSelected: (i) =>
                  _playerController?.selectSubtitleTrack(i),
            ),

          // ── 错误提示 ──
          if (state != null && state.hasError)
            Positioned(
              bottom: 120,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  播放器控制面板覆盖层
// ══════════════════════════════════════════════════════════════════

/// 全屏播放器控制面板
///
/// 包含：
/// - 顶部：返回按钮、标题、设置菜单
/// - 底部：进度条、播放控制、时间标签、倍速、音轨、字幕
class _PlayerControlsOverlay extends StatelessWidget {
  final PlayerUiState state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onMuteToggle;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int> onAudioTrackSelected;
  final ValueChanged<int> onSubtitleTrackSelected;

  const _PlayerControlsOverlay({
    required this.state,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onVolumeChanged,
    required this.onMuteToggle,
    required this.onSpeedChanged,
    required this.onAudioTrackSelected,
    required this.onSubtitleTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: state.showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Stack(
        children: [
          // ── 顶部渐变遮罩 + 返回/标题 ──
          _buildTopBar(context),

          // ── 底部渐变遮罩 + 控制栏 ──
          _buildBottomBar(context),

          // ── 中央播放按钮（暂停时显示） ──
          if (!state.isPlaying && !state.isBuffering)
            Center(
              child: GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.celestialCyan.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.celestialCyan.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.celestialCyan,
                    size: 40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 顶部控制栏（返回 + 标题 + 设置）
  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              MediaQuery.of(context).padding.top + 4,
              16,
              0,
            ),
            child: Row(
              children: [
                // 返回按钮
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 26),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                // 标题
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.title.isNotEmpty ? state.title : '正在播放',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 设置菜单
                PopupMenuButton<double>(
                  icon: const Icon(Icons.settings_rounded,
                      color: Colors.white70, size: 22),
                  color: AppColors.stardust,
                  onSelected: (speed) => onSpeedChanged(speed),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 1.0,
                      child: Text('倍速', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    ...state.speedOptions
                        .where((s) => s != 1.0)
                        .map(
                          (s) => PopupMenuItem(
                            value: s,
                            child: Text(
                              '${s}x',
                              style: TextStyle(
                                color: state.playbackSpeed == s
                                    ? AppColors.celestialCyan
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 底部控制栏（进度条 + 播放控制 + 功能按钮）
  Widget _buildBottomBar(BuildContext context) {
    final progress = state.progress;
    final isMuted = state.volume == 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              32,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 进度条 ──
                _buildProgressBar(progress),

                const SizedBox(height: 12),

                // ── 控制按钮行 ──
                _buildControlButtons(isMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 进度条（可拖拽）
  Widget _buildProgressBar(double progress) {
    return Row(
      children: [
        // 当前位置
        Text(
          PlayerController.formatDuration(state.position),
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        // 进度滑块
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.celestialCyan,
              inactiveTrackColor: AppColors.cosmicGray,
              thumbColor: AppColors.celestialCyan,
              overlayColor: AppColors.celestialCyan.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: progress,
              onChanged: onSeek,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 总时长
        Text(
          PlayerController.formatDuration(state.duration),
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// 控制按钮行
  Widget _buildControlButtons(bool isMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 音量 / 静音
        IconButton(
          icon: Icon(
            isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          onPressed: onMuteToggle,
        ),

        // 音量滑块
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.celestialCyan,
              inactiveTrackColor: AppColors.cosmicGray,
              thumbColor: AppColors.celestialCyan,
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 4),
            ),
            child: Slider(
              value: isMuted ? 0 : state.volume,
              onChanged: onVolumeChanged,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // 快退 10s
        IconButton(
          icon: const Icon(Icons.replay_10_rounded,
              color: Colors.white, size: 28),
          onPressed: onSeekBackward,
        ),

        const SizedBox(width: 16),

        // 播放 / 暂停
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.celestialCyan,
            boxShadow: [
              BoxShadow(
                color: AppColors.celestialCyan.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              state.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: AppColors.deepVoid,
              size: 30,
            ),
            onPressed: onPlayPause,
          ),
        ),

        const SizedBox(width: 16),

        // 快进 30s
        IconButton(
          icon: const Icon(Icons.forward_30_rounded,
              color: Colors.white, size: 28),
          onPressed: onSeekForward,
        ),

        const SizedBox(width: 8),

        // 字幕按钮
        if (state.subtitleTracks.isNotEmpty)
          PopupMenuButton<int>(
            icon: Icon(
              Icons.subtitles_rounded,
              color: state.currentSubtitleTrack >= 0
                  ? AppColors.celestialCyan
                  : AppColors.textSecondary,
              size: 22,
            ),
            color: AppColors.stardust,
            onSelected: (index) => onSubtitleTrackSelected(index),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: -1,
                child: Text('关闭字幕',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
              ...state.subtitleTracks.asMap().entries.map(
                    (entry) => PopupMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value.title.isNotEmpty
                            ? entry.value.title
                            : '轨道 ${entry.key + 1}',
                        style: TextStyle(
                          color: state.currentSubtitleTrack == entry.key
                              ? AppColors.celestialCyan
                              : AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
            ],
          ),

        // 音频轨道按钮
        if (state.audioTracks.length > 1)
          PopupMenuButton<int>(
            icon: const Icon(Icons.audiotrack_rounded,
                color: AppColors.textSecondary, size: 22),
            color: AppColors.stardust,
            onSelected: (index) => onAudioTrackSelected(index),
            itemBuilder: (context) => state.audioTracks
                .asMap()
                .entries
                .map(
                  (entry) => PopupMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value.title.isNotEmpty
                          ? entry.value.title
                          : '轨道 ${entry.key + 1}',
                      style: TextStyle(
                        color: state.currentAudioTrack == entry.key
                            ? AppColors.celestialCyan
                            : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

        const SizedBox(width: 4),

        // 倍速显示
        GestureDetector(
          onTap: () {
            // 循环切换倍速
            final speeds = state.speedOptions;
            final currentIndex = speeds.indexOf(state.playbackSpeed);
            final nextIndex = (currentIndex + 1) % speeds.length;
            onSpeedChanged(speeds[nextIndex]);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.stardust,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle, width: 0.5),
            ),
            child: Text(
              '${state.playbackSpeed}x',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
