import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/player_engine.dart';
import '../services/mpv_engine.dart';

// ══════════════════════════════════════════════════════════════════
//  播放器 UI 状态
// ══════════════════════════════════════════════════════════════════

class PlayerUiState {
  /// 播放器核心状态
  final PlayerState playerState;

  /// 当前播放位置
  final Duration position;

  /// 媒体总时长
  final Duration duration;

  /// 是否正在缓冲
  final bool isBuffering;

  /// 是否显示控制面板
  final bool showControls;

  /// 当前音量 (0.0 ~ 1.0)
  final double volume;

  /// 播放倍速
  final double playbackSpeed;

  /// 错误信息
  final String? error;

  /// 可用音频轨道列表
  final List<TrackInfo> audioTracks;

  /// 可用字幕轨道列表
  final List<TrackInfo> subtitleTracks;

  /// 当前音频轨道索引
  final int currentAudioTrack;

  /// 当前字幕轨道索引（-1 = 关闭字幕）
  final int currentSubtitleTrack;

  /// 媒体标题
  final String title;

  /// 流 URL（已解析）
  final String? streamUrl;

  /// 播放会话 ID（用于 Emby 上报）
  final String? playSessionId;

  /// 当前播放的媒体源 ID
  final String? mediaSourceId;

  /// 当前正在播放的媒体项 ID
  final String? itemId;

  /// 倍速选项列表
  final List<double> speedOptions;

  /// 是否正在 seek（用于 UI 展示）
  final bool isSeeking;

  const PlayerUiState({
    this.playerState = PlayerState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isBuffering = false,
    this.showControls = true,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.error,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.currentAudioTrack = 0,
    this.currentSubtitleTrack = -1,
    this.title = '',
    this.streamUrl,
    this.playSessionId,
    this.mediaSourceId,
    this.itemId,
    this.speedOptions = const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
    this.isSeeking = false,
  });

  /// 是否正在播放
  bool get isPlaying => playerState == PlayerState.playing;

  /// 是否处于错误状态
  bool get hasError => error != null;

  /// 进度百分比 (0.0 ~ 1.0)
  double get progress =>
      duration.inMilliseconds > 0
          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

  PlayerUiState copyWith({
    PlayerState? playerState,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    bool? showControls,
    double? volume,
    double? playbackSpeed,
    String? error,
    List<TrackInfo>? audioTracks,
    List<TrackInfo>? subtitleTracks,
    int? currentAudioTrack,
    int? currentSubtitleTrack,
    String? title,
    String? streamUrl,
    String? playSessionId,
    String? mediaSourceId,
    String? itemId,
    List<double>? speedOptions,
    bool? isSeeking,
  }) {
    return PlayerUiState(
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      showControls: showControls ?? this.showControls,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      error: error, // 允许设为 null 来清除错误
      audioTracks: audioTracks ?? this.audioTracks,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      currentAudioTrack: currentAudioTrack ?? this.currentAudioTrack,
      currentSubtitleTrack:
          currentSubtitleTrack ?? this.currentSubtitleTrack,
      title: title ?? this.title,
      streamUrl: streamUrl ?? this.streamUrl,
      playSessionId: playSessionId ?? this.playSessionId,
      mediaSourceId: mediaSourceId ?? this.mediaSourceId,
      itemId: itemId ?? this.itemId,
      speedOptions: speedOptions ?? this.speedOptions,
      isSeeking: isSeeking ?? this.isSeeking,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  播放器控制器
// ══════════════════════════════════════════════════════════════════

class PlayerController extends StateNotifier<PlayerUiState> {
  final PlayerEngine _engine;
  final ApiClient _api;
  final String serverUrl;
  final String token;
  final String userId;

  /// 进度上报定时器（每 10 秒）
  Timer? _progressTimer;

  /// 控制面板自动隐藏定时器
  Timer? _controlsHideTimer;

  /// 引擎事件订阅
  final List<StreamSubscription> _subscriptions = [];

  PlayerController({
    required this.serverUrl,
    required this.token,
    required this.userId,
    PlayerEngine? engine,
    ApiClient? api,
  })  : _engine = engine ?? MpvEngine(),
        _api = api ?? ApiClient(),
        super(const PlayerUiState()) {
    _listenToEngine();
  }

  /// 暴露底层引擎给 UI（用于创建 Video widget）
  PlayerEngine get engine => _engine;

  /// 获取当前播放器 UI 状态（供外部读取）
  PlayerUiState get currentState => state;

  /// 监听引擎事件并更新 UI 状态
  void _listenToEngine() {
    // 播放状态
    _subscriptions.add(_engine.stateStream.listen((s) {
      if (!mounted) return;
      state = state.copyWith(playerState: s);
    }));

    // 播放位置
    _subscriptions.add(_engine.positionStream.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    }));

    // 总时长
    _subscriptions.add(_engine.durationStream.listen((dur) {
      if (!mounted) return;
      state = state.copyWith(duration: dur);
    }));

    // 缓冲状态
    _subscriptions.add(_engine.bufferingStream.listen((buffering) {
      if (!mounted) return;
      state = state.copyWith(isBuffering: buffering);
    }));

    // 播放完成时刷新轨道列表
    _subscriptions.add(_engine.completionStream.listen((_) {
      if (!mounted) return;
      // 播放完成后更新轨道信息
      state = state.copyWith(
        audioTracks: _engine.audioTracks,
        subtitleTracks: _engine.subtitleTracks,
      );
    }));

    // 定时同步轨道信息（引擎内部更新后刷新到 UI）
    _syncTracks();
  }

  /// 同步引擎的轨道信息到 UI 状态
  void _syncTracks() {
    if (!mounted) return;
    final audioTracks = _engine.audioTracks;
    final subtitleTracks = _engine.subtitleTracks;
    if (audioTracks.isNotEmpty || subtitleTracks.isNotEmpty) {
      state = state.copyWith(
        audioTracks: audioTracks,
        subtitleTracks: subtitleTracks,
        currentAudioTrack: _engine.currentAudioTrackIndex,
        currentSubtitleTrack: _engine.currentSubtitleTrackIndex,
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  //  加载与播放
  // ══════════════════════════════════════════════════════════

  /// 加载媒体并开始播放
  ///
  /// 流程：
  /// 1. 从 Emby 服务器获取播放信息
  /// 2. 获取流 URL
  /// 3. 打开播放器并开始播放
  /// 4. 如有起始位置则 seek
  /// 5. 上报播放开始
  /// 6. 启动进度上报
  Future<void> loadAndPlay(
    String itemId, {
    String title = '',
    int startAtMs = 0,
  }) async {
    try {
      state = state.copyWith(
        error: null,
        title: title,
        itemId: itemId,
      );

      // ── 第 1 步：获取播放信息 ──
      final playbackInfo = await _api.getPlaybackInfo(
        serverUrl: serverUrl,
        token: token,
        userId: userId,
        itemId: itemId,
      );

      final mediaSourceId = playbackInfo.mediaSources.isNotEmpty
          ? playbackInfo.mediaSources.first.id
          : '';
      final playSessionId = playbackInfo.playSessionId;

      state = state.copyWith(
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
      );

      // ── 第 2 步：获取流 URL ──
      final streamUrl = await _api.getVideoStreamUrl(
        serverUrl: serverUrl,
        token: token,
        itemId: itemId,
      );

      state = state.copyWith(streamUrl: streamUrl);

      // ── 第 3 步：打开播放器 ──
      await _engine.open(
        streamUrl,
        headers: {
          'Authorization': 'MediaBrowser Token="$token"',
          'X-Emby-Token': token,
        },
      );

      // ── 第 4 步：Seek 到起始位置 ──
      if (startAtMs > 0) {
        await _engine.seek(Duration(milliseconds: startAtMs));
      }

      // ── 第 5 步：上报播放开始 ──
      await _api.reportPlaybackStarted(
        serverUrl: serverUrl,
        token: token,
        itemId: itemId,
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
      );

      // ── 第 6 步：启动进度上报 ──
      _startProgressReporting(itemId, mediaSourceId, playSessionId);

      // 同步轨道信息
      _syncTracks();

      // 重置控制面板自动隐藏计时器
      _resetControlsHideTimer();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  // ══════════════════════════════════════════════════════════
  //  播放控制
  // ══════════════════════════════════════════════════════════

  /// 切换播放 / 暂停
  void togglePlayPause() {
    _engine.togglePlay();
    _resetControlsHideTimer();
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _engine.seek(position);
    _resetControlsHideTimer();
  }

  /// 前进指定秒数（默认 10 秒）
  void seekForward([int seconds = 10]) {
    final newPos = state.position + Duration(seconds: seconds);
    final clamped = newPos > state.duration ? state.duration : newPos;
    seek(clamped);
  }

  /// 后退指定秒数（默认 10 秒）
  void seekBackward([int seconds = 10]) {
    final newPos = state.position - Duration(seconds: seconds);
    final clamped = newPos < Duration.zero ? Duration.zero : newPos;
    seek(clamped);
  }

  /// 从进度条拖拽 seek（传入百分比 0.0~1.0）
  void seekToProgress(double progress) {
    if (state.duration.inMilliseconds <= 0) return;
    final targetMs =
        (progress * state.duration.inMilliseconds).round();
    seek(Duration(milliseconds: targetMs));
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    await _engine.setVolume(clamped);
    state = state.copyWith(volume: clamped);
    _resetControlsHideTimer();
  }

  /// 切换静音
  void toggleMute() {
    if (state.volume > 0) {
      setVolume(0);
    } else {
      setVolume(1.0);
    }
  }

  /// 设置播放倍速
  Future<void> setPlaybackSpeed(double speed) async {
    await _engine.setPlaybackSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
    _resetControlsHideTimer();
  }

  // ══════════════════════════════════════════════════════════
  //  轨道选择
  // ══════════════════════════════════════════════════════════

  /// 选择音频轨道
  Future<void> selectAudioTrack(int index) async {
    await _engine.setAudioTrack(index);
    state = state.copyWith(currentAudioTrack: index);
    _resetControlsHideTimer();
  }

  /// 选择字幕轨道（传入索引，-1 表示关闭）
  Future<void> selectSubtitleTrack(int index) async {
    await _engine.setSubtitleTrack(index);
    state = state.copyWith(currentSubtitleTrack: index);
    _resetControlsHideTimer();
  }

  // ══════════════════════════════════════════════════════════
  //  控制面板显示逻辑
  // ══════════════════════════════════════════════════════════

  /// 切换控制面板显示 / 隐藏
  void toggleControls() {
    final newShow = !state.showControls;
    state = state.copyWith(showControls: newShow);
    if (newShow) {
      _resetControlsHideTimer();
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  /// 显示控制面板并重置自动隐藏计时器
  void showControlsTemporarily() {
    state = state.copyWith(showControls: true);
    _resetControlsHideTimer();
  }

  /// 重置控制面板自动隐藏计时器（5 秒无操作后隐藏）
  void _resetControlsHideTimer() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && state.isPlaying) {
        state = state.copyWith(showControls: false);
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  //  Emby 进度上报
  // ══════════════════════════════════════════════════════════

  /// 启动定时进度上报（每 10 秒向 Emby 服务器发送进度）
  void _startProgressReporting(
    String itemId,
    String mediaSourceId,
    String playSessionId,
  ) {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportProgress(itemId, mediaSourceId, playSessionId);
    });
  }

  /// 单次上报播放进度
  Future<void> _reportProgress(
    String itemId,
    String mediaSourceId,
    String playSessionId,
  ) async {
    if (!mounted) return;
    try {
      // 将位置转换为 ticks（1 tick = 100 纳秒 = 0.0000001 秒）
      final positionTicks = state.position.inMicroseconds * 10;
      await _api.reportPlaybackProgress(
        serverUrl: serverUrl,
        token: token,
        itemId: itemId,
        positionTicks: positionTicks,
        isPaused: !state.isPlaying,
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
      );
    } catch (_) {
      // 进度上报失败时静默忽略
    }
  }

  // ══════════════════════════════════════════════════════════
  //  停止播放（上报 Emby）
  // ══════════════════════════════════════════════════════════

  /// 停止播放并上报 Emby 服务器
  Future<void> reportStopped() async {
    _progressTimer?.cancel();
    _controlsHideTimer?.cancel();

    if (state.itemId == null) return;
    try {
      final positionTicks = state.position.inMicroseconds * 10;
      await _api.reportPlaybackStopped(
        serverUrl: serverUrl,
        token: token,
        itemId: state.itemId!,
        positionTicks: positionTicks,
        mediaSourceId: state.mediaSourceId ?? '',
        playSessionId: state.playSessionId ?? '',
      );
    } catch (_) {
      // 上报失败时静默忽略
    }
  }

  // ══════════════════════════════════════════════════════════
  //  格式化辅助
  // ══════════════════════════════════════════════════════════

  /// 格式化时间为 HH:MM:SS 或 MM:SS
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ══════════════════════════════════════════════════════════
  //  生命周期
  // ══════════════════════════════════════════════════════════

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controlsHideTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _engine.dispose();
    super.dispose();
  }
}
