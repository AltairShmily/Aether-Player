import 'dart:async';

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
import '../services/api_client.dart';
import '../services/player_engine_factory.dart';
import '../services/playback_strategy.dart';
import '../widgets/player_error_card.dart';
import '../widgets/quality_selector.dart';
import '../widgets/video_osd.dart';

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

  /// 自动播放下一集所需信息。
  /// 当前集的位置由 [itemId] 在剧集列表中反查，无需额外传索引。
  final String? seriesId;
  final String? seasonId;

  const PlayerPage({
    super.key,
    required this.itemId,
    required this.title,
    this.startAtMs = 0,
    this.audioTrackIndex,
    this.subtitleTrackIndex,
    this.seriesId,
    this.seasonId,
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

      // 预取下一集，使"下一集"按钮全程可用。
      // 不 await：不应阻塞播放初始化，失败也不影响当前播放
      unawaited(_loadNextEpisode());
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

  /// 预取下一集信息。
  ///
  /// 必须在播放开始时就调用：_nextEpisodeId 此前只在播放完成后才填充，
  /// 导致"下一集"按钮即使显示出来，点击也会因 ID 为空而毫无反应。
  Future<void> _loadNextEpisode() async {
    final seriesId = widget.seriesId;
    final seasonId = widget.seasonId;
    if (seriesId == null || seasonId == null) return;
    if (_nextEpisodeId.isNotEmpty) return; // 已加载，避免重复请求

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
        seriesId: seriesId,
        seasonId: seasonId,
      );
      final episodes = response.items;
      if (!mounted || episodes.isEmpty) return;

      // 当前集在列表中的位置由 itemId 反查，无需调用方额外传索引
      final currentIndex = episodes.indexWhere((e) => e.id == widget.itemId);
      if (currentIndex < 0 || currentIndex >= episodes.length - 1) return;

      final nextEp = episodes[currentIndex + 1];
      setState(() {
        _nextEpisodeId = nextEp.id;
        _nextEpisodeTitle = nextEp.name;
      });
    } catch (e) {
      debugPrint('[PlayerPage] Load next episode failed: $e');
    }
  }

  /// 播放结束后按用户设置决定是否自动续播下一集
  Future<void> _checkAutoPlayNext() async {
    final autoPlay =
        await ref.read(settingsServiceProvider).getAutoPlayNext();
    if (!autoPlay || !mounted) return;

    // 正常情况下开播时已预取，这里只是兜底
    await _loadNextEpisode();
    if (!mounted || _nextEpisodeId.isEmpty) return;

    _startAutoPlayCountdown();
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
            Center(child: _buildBufferingIndicator(state)),

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
            VideoOsd(
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
              // 仅在确实取到下一集时才显示按钮，
              // 否则按钮出现却点不动（_playNextEpisode 会因 ID 为空直接返回）
              onSkipNext: _nextEpisodeId.isNotEmpty ? _playNextEpisode : null,
            ),

          // ── 错误卡片 ──
          if (state != null && state.hasError)
            Positioned.fill(
              child: PlayerErrorCard(
                message: state.error!,
                onRetry: () => _playerController?.retry(),
                onSwitchQuality: () => _showQualitySelector(context),
                onBack: () => Navigator.of(context).pop(),
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

  /// 加载 / 缓冲指示器。
  ///
  /// 光转圈无法区分"正在缓冲"与"已经卡死"，引擎上报了缓存填充进度就把数字带上。
  /// 不上报时（原生 FFI 引擎）只显示转圈 —— 用 0% 冒充会被读成"完全没缓冲"。
  Widget _buildBufferingIndicator(PlayerUiState? state) {
    final percent = state?.bufferingPercent;
    // 已缓冲满时数字没有信息量，且会在恢复播放前的一瞬间停在 100%
    final label = (percent != null && percent < 100)
        ? '缓冲中 ${percent.round()}%'
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: AppColors.celestialCyan,
            strokeWidth: 2,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'DM Mono',
            ),
          ),
        ],
      ],
    );
  }
}

