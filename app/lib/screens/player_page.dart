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
import '../providers/settings_provider.dart';
import '../services/mpv_engine.dart';
import '../services/settings_service.dart';
import '../services/api_client.dart';
import '../services/player_engine_factory.dart';
import '../services/playback_strategy.dart';
import '../widgets/quality_selector.dart';

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

  /// 预选音频轨道索引（在流加载后自动应用）
  final int? audioTrackIndex;

  /// 预选字幕轨道索引（-1 = 关闭字幕，在流加载后自动应用）
  final int? subtitleTrackIndex;

  /// 自动播放下一集所需信息
  final String? seriesId;
  final String? seasonId;
  final int? episodeIndex;

  const PlayerPage({
    super.key,
    required this.itemId,
    required this.title,
    this.startAtMs = 0,
    this.audioTrackIndex,
    this.subtitleTrackIndex,
    this.seriesId,
    this.seasonId,
    this.episodeIndex,
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

  // 自动播放下一集
  bool _showAutoPlayOverlay = false;
  int _autoPlayCountdown = 8;
  Timer? _autoPlayTimer;
  String _nextEpisodeTitle = '';
  String _nextEpisodeId = '';

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

    // 根据用户设置创建对应引擎
    final engineType = ref.read(playerEngineProvider);
    final engine = PlayerEngineFactory.create(engineType);

    // 创建控制器（传入指定引擎）
    final controller = PlayerController(
      serverUrl: serverUrl,
      token: auth.token,
      userId: auth.user.id,
      engine: engine,
    );

    // 根据引擎类型获取 VideoController（仅 media_kit 引擎需要）
    if (engine is MpvEngine) {
      _videoController = engine.videoController;
    }

    // 保存 controller 到 state 以便后续访问
    _playerController = controller;

    // 监听播放状态变更：PlayerController 是手动创建的 StateNotifier，
    // 不在 Riverpod 管理范围内，必须显式监听才能驱动 UI 重建
    _removePlayerListener = controller.addListener(_onPlayerStateChanged);

    // 设置播放完成回调（自动播放下一集）
    controller.onPlaybackComplete = _onPlaybackComplete;

    if (mounted) {
      setState(() => _isInitialized = true);

      // 开始播放
      await controller.loadAndPlay(
        widget.itemId,
        title: widget.title,
        startAtMs: widget.startAtMs,
      );

      // 应用预选的音频/字幕轨道（在流加载完成后）。
      // null 表示用户未作选择，交由引擎使用默认轨道；
      // 索引 0 是合法的第一条轨道，不能用 > 0 过滤掉
      if (widget.audioTrackIndex != null) {
        await controller.selectAudioTrack(widget.audioTrackIndex!);
      }
      if (widget.subtitleTrackIndex != null) {
        await controller.selectSubtitleTrack(widget.subtitleTrackIndex!);
      }
    }
  }

  // PlayerController 的引用（非 Riverpod 管理，手动创建）
  PlayerController? _playerController;

  /// addListener 返回的注销闭包（StateNotifier 无 removeListener 方法）
  void Function()? _removePlayerListener;

  /// 播放状态变更回调 —— 驱动播放器 UI 重建
  void _onPlayerStateChanged(PlayerUiState _) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // 注销状态监听，避免控制器持有已销毁的 State
    _removePlayerListener?.call();
    _removePlayerListener = null;

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
    _autoPlayTimer?.cancel();

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

  // ── 画质选择 ──────────────────────────────────────────────

  /// 显示画质选择面板
  void _showQualitySelector(BuildContext context) {
    final controller = _playerController;
    if (controller == null) return;

    final mediaSource = controller.currentMediaSource;
    if (mediaSource == null) return;

    final options = QualitySelector.fromMediaSource(mediaSource);
    if (options.isEmpty) return;

    // 根据当前播放模式确定选中项
    final currentState = controller.currentState;
    QualityOption? current;
    if (currentState.currentPlayMode == PlayMode.transcode) {
      current = options.where((o) => o.mode == PlayMode.transcode).firstOrNull;
    } else {
      current = options.where((o) => o.mode == PlayMode.directPlay).firstOrNull;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => QualitySelector(
        options: options,
        current: current,
        onSelected: (opt) {
          final itemId = controller.currentItemId;
          if (itemId == null) return;
          controller.switchQuality(
            itemId: itemId,
            mode: opt.mode,
            maxBitrate: opt.maxBitrate,
            maxHeight: opt.maxHeight,
          );
        },
      ),
    );
  }

  // ── 自动播放下一集 ──────────────────────────────────────

  /// 播放完成回调
  void _onPlaybackComplete() {
    if (!mounted) return;
    _checkAutoPlayNext();
  }

  /// 检查是否需要自动播放下一集
  Future<void> _checkAutoPlayNext() async {
    final settings = SettingsService();
    final autoPlay = await settings.getAutoPlayNext();
    if (!autoPlay || !mounted) return;

    if (widget.seriesId == null ||
        widget.seasonId == null ||
        widget.episodeIndex == null) {
      return;
    }

    try {
      final api = ApiClient();
      final auth = ref.read(authProvider).authResult;
      final serverUrl =
          await ref.read(storageServiceProvider).getServerUrl();
      if (auth == null || serverUrl == null || !mounted) return;

      final response = await api.getEpisodes(
        serverUrl: serverUrl,
        token: auth.token,
        userId: auth.user.id,
        seriesId: widget.seriesId!,
        seasonId: widget.seasonId!,
      );
      final episodes = response.items;

      if (!mounted || episodes.isEmpty) return;

      final currentIndex =
          episodes.indexWhere((e) => e.id == widget.itemId);
      if (currentIndex < 0 || currentIndex >= episodes.length - 1) return;

      final nextEp = episodes[currentIndex + 1];
      _nextEpisodeId = nextEp.id;
      _nextEpisodeTitle = nextEp.name;
      _startAutoPlayCountdown();
    } catch (e) {
      debugPrint('[PlayerPage] Auto-play check failed: $e');
    }
  }

  /// 开始自动播放倒计时
  void _startAutoPlayCountdown() {
    if (!mounted) return;
    setState(() {
      _showAutoPlayOverlay = true;
      _autoPlayCountdown = 8;
    });

    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoPlayCountdown <= 1) {
        timer.cancel();
        _playNextEpisode();
      } else {
        setState(() => _autoPlayCountdown--);
      }
    });
  }

  /// 取消自动播放
  void _cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    if (mounted) setState(() => _showAutoPlayOverlay = false);
  }

  /// 播放下一集
  Future<void> _playNextEpisode() async {
    _autoPlayTimer?.cancel();
    if (!mounted || _nextEpisodeId.isEmpty) return;

    setState(() {
      _showAutoPlayOverlay = false;
      _isInitialized = false;
    });

    await _playerController?.reportStopped();
    await _playerController?.loadAndPlay(
      _nextEpisodeId,
      title: _nextEpisodeTitle,
    );

    if (mounted) setState(() => _isInitialized = true);
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
            )
          // 原生引擎占位（视频渲染需要平台 Texture 集成）
          else if (_isInitialized && _videoController == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline_rounded,
                      color: AppColors.celestialCyan, size: 64),
                  SizedBox(height: 16),
                  Text(
                    '原生引擎 · 音频播放中',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '视频渲染开发中…',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                      fontFamily: 'DM Mono',
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
              onQualityPressed: () => _showQualitySelector(context),
              onSkipNext: widget.seriesId != null ? _playNextEpisode : null,
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

          // ── 播放模式标签 ──
          if (state != null && state.currentPlayMode != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.currentPlayMode == PlayMode.directPlay
                      ? Colors.green.withValues(alpha: 0.7)
                      : Colors.orange.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  state.currentPlayMode == PlayMode.directPlay
                      ? 'Direct Play'
                      : 'Transcode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ── 自动播放下一集倒计时 ──
          if (_showAutoPlayOverlay)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.celestialCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.celestialCyan,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '即将播放下一集',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nextEpisodeTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _autoPlayCountdown / 8,
                            color: AppColors.celestialCyan,
                            backgroundColor: AppColors.cosmicGray,
                            strokeWidth: 3,
                          ),
                          Text(
                            '$_autoPlayCountdown',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _cancelAutoPlay,
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: _playNextEpisode,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.celestialCyan,
                            foregroundColor: AppColors.deepVoid,
                          ),
                          child: const Text('立即播放'),
                        ),
                      ],
                    ),
                  ],
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
  final VoidCallback? onQualityPressed;
  final VoidCallback? onSkipNext;

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
    this.onQualityPressed,
    this.onSkipNext,
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
                // 统一设置按钮
                IconButton(
                  icon: const Icon(Icons.settings_rounded,
                      color: Colors.white70, size: 22),
                  onPressed: () => _showSettingsSheet(context),
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
                _buildControlButtons(context, isMuted),
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
            fontFamily: 'DM Mono',
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
            fontFamily: 'DM Mono',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// 控制按钮行
  Widget _buildControlButtons(BuildContext context, bool isMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── 左侧：快退 + 播放/暂停 + 快进 + 下一集 ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快退 10s
            IconButton(
              icon: const Icon(Icons.replay_10_rounded,
                  color: Colors.white, size: 28),
              onPressed: onSeekBackward,
            ),

            const SizedBox(width: 12),

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

            const SizedBox(width: 12),

            // 快进 30s
            IconButton(
              icon: const Icon(Icons.forward_30_rounded,
                  color: Colors.white, size: 28),
              onPressed: onSeekForward,
            ),

            // 下一集按钮（仅在有 seriesId 时显示）
            if (onSkipNext != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    color: Colors.white, size: 28),
                onPressed: onSkipNext,
              ),
            ],
          ],
        ),

        // ── 右侧：音量 + 倍速 + 设置 ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 音量图标 + 滑块（合并）
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              onPressed: onMuteToggle,
            ),
            SizedBox(
              width: 70,
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

            // 倍速标签
            GestureDetector(
              onTap: () {
                final speeds = state.speedOptions;
                final currentIndex = speeds.indexOf(state.playbackSpeed);
                final nextIndex = (currentIndex + 1) % speeds.length;
                onSpeedChanged(speeds[nextIndex]);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.stardust,
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppColors.borderSubtle, width: 0.5),
                ),
                child: Text(
                  '${state.playbackSpeed}x',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'DM Mono',
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            // 统一设置菜单按钮
            IconButton(
              icon: const Icon(Icons.tune_rounded,
                  color: Colors.white70, size: 22),
              onPressed: () => _showSettingsSheet(context),
            ),
          ],
        ),
      ],
    );
  }

  /// 统一设置面板（底部弹出）
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: AppColors.stardust,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 拖拽条
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cosmicGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 标题
                const Text(
                  '设置',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // ── 倍速选择 ──
                const Text(
                  '🎬 倍速',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.speedOptions.map((speed) {
                    final isSelected = state.playbackSpeed == speed;
                    return GestureDetector(
                      onTap: () {
                        onSpeedChanged(speed);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.celestialCyan
                              : AppColors.deepVoid,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.celestialCyan
                                : AppColors.borderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.deepVoid
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── 音频轨道 ──
                if (state.audioTracks.length > 1) ...[
                  const Text(
                    '🎵 音轨',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.audioTracks.asMap().entries.map((entry) {
                    final isSelected = state.currentAudioTrack == entry.key;
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        entry.value.title.isNotEmpty
                            ? entry.value.title
                            : '轨道 ${entry.key + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.celestialCyan
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.celestialCyan, size: 20)
                          : null,
                      onTap: () {
                        onAudioTrackSelected(entry.key);
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── 字幕轨道 ──
                if (state.subtitleTracks.isNotEmpty) ...[
                  const Text(
                    '📝 字幕',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 关闭字幕选项
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(
                      '关闭字幕',
                      style: TextStyle(
                        color: state.currentSubtitleTrack < 0
                            ? AppColors.celestialCyan
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: state.currentSubtitleTrack < 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: state.currentSubtitleTrack < 0
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.celestialCyan, size: 20)
                        : null,
                    onTap: () {
                      onSubtitleTrackSelected(-1);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ...state.subtitleTracks.asMap().entries.map((entry) {
                    final isSelected =
                        state.currentSubtitleTrack == entry.key;
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        entry.value.title.isNotEmpty
                            ? entry.value.title
                            : '轨道 ${entry.key + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.celestialCyan
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.celestialCyan, size: 20)
                          : null,
                      onTap: () {
                        onSubtitleTrackSelected(entry.key);
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── 画质选项 ──
                if (onQualityPressed != null) ...[
                  const Text(
                    '🎨 画质',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      '画质设置',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onQualityPressed!();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
