import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/player_engine.dart';
import '../services/mpv_engine.dart';
import '../services/playback_strategy.dart';
import '../models/playback_models.dart' hide TrackInfo;

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

  /// 当前播放模式
  final PlayMode? currentPlayMode;

  /// 播放模式原因
  final String? playModeReason;

  /// 已缓冲到的位置；null 表示当前引擎不上报，进度条应省略缓冲段
  final Duration? bufferedPosition;

  /// 缓存填充百分比（0-100）；null 表示当前引擎不上报
  final double? bufferingPercent;

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
    this.currentPlayMode,
    this.playModeReason,
    this.bufferedPosition,
    this.bufferingPercent,
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

  /// 区分「调用方未传该参数」与「显式传 null」的哨兵。
  ///
  /// 可空字段若用 `??` 就永远清不掉，若直接赋值又会被无关的 copyWith 抹掉
  /// （error 曾因此刚显示就被下一次 position 更新清除）。
  static const Object _unset = Object();

  PlayerUiState copyWith({
    PlayerState? playerState,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    bool? showControls,
    double? volume,
    double? playbackSpeed,
    Object? error = _unset,
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
    PlayMode? currentPlayMode,
    String? playModeReason,
    Object? bufferedPosition = _unset,
    Object? bufferingPercent = _unset,
  }) {
    return PlayerUiState(
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      showControls: showControls ?? this.showControls,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      // 显式传 null 才清除错误，未传参时保留原值
      error: identical(error, _unset) ? this.error : error as String?,
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
      currentPlayMode: currentPlayMode ?? this.currentPlayMode,
      playModeReason: playModeReason ?? this.playModeReason,
      bufferedPosition: identical(bufferedPosition, _unset)
          ? this.bufferedPosition
          : bufferedPosition as Duration?,
      bufferingPercent: identical(bufferingPercent, _unset)
          ? this.bufferingPercent
          : bufferingPercent as double?,
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

  /// 缓冲期间刷新缓冲段与百分比的轮询定时器
  Timer? _bufferPollTimer;

  /// 引擎事件订阅
  final List<StreamSubscription> _subscriptions = [];

  /// 播放完成回调（用于自动播放下一集等）
  void Function()? onPlaybackComplete;

  /// 真正的直连（Direct Play）地址。
  ///
  /// 必须与 `state.streamUrl` 分开保存：初始策略决策为转码时，后者是
  /// 转码地址，用户切回"原始画质"若复用它，实际仍在播转码流。
  /// 直连地址需要额外请求获取，故按需拉取并缓存。
  String? _directPlayUrl;

  /// 静音前的音量，取消静音时恢复到该值而非固定的 1.0
  double _volumeBeforeMute = 1.0;

  /// 来自 Emby 元数据（RunTimeTicks）的权威时长。
  ///
  /// 播放引擎从流中读到的时长并不可靠 —— 转码流尤其如此，
  /// 表现为总时长显示错误。元数据存在时一律优先采用。
  Duration? _metadataDuration;

  /// Emby 以 External 方式提供的字幕流。
  ///
  /// 转码流无法内嵌文本字幕，此时引擎从流中发现不到任何字幕轨道，
  /// 必须改用这些外挂地址，否则用户在转码播放时完全没有字幕可选。
  List<PlaybackStreamInfo> _externalSubtitles = const [];

  /// 是否应走外挂字幕：仅当引擎没从流里发现字幕、而 Emby 提供了外挂地址时
  bool get _useExternalSubtitles =>
      _engine.subtitleTracks.isEmpty && _externalSubtitles.isNotEmpty;

  /// UI 可见的字幕列表：优先用引擎从流中发现的轨道，
  /// 为空时回退到 Emby 提供的外挂字幕
  List<TrackInfo> get _effectiveSubtitleTracks {
    final engineTracks = _engine.subtitleTracks;
    if (engineTracks.isNotEmpty || _externalSubtitles.isEmpty) {
      return engineTracks;
    }
    return [
      for (var i = 0; i < _externalSubtitles.length; i++)
        TrackInfo(
          index: i,
          language: _externalSubtitles[i].language,
          title: _externalSubtitles[i].displayTitle,
          codec: _externalSubtitles[i].codec,
          type: 'subtitle',
        ),
    ];
  }

  /// 当前播放的媒体源信息（用于画质选择器）
  MediaSourceInfo? _currentMediaSource;

  PlayerController({
    required this.serverUrl,
    required this.token,
    required this.userId,
    PlayerEngine? engine,
    ApiClient? api,
  }) : _engine = engine ?? MpvEngine(),
       _api = api ?? ApiClient(),
       super(const PlayerUiState()) {
    _listenToEngine();
  }

  /// 暴露底层引擎给 UI（用于创建 Video widget）
  PlayerEngine get engine => _engine;

  /// 获取当前播放器 UI 状态（供外部读取）
  PlayerUiState get currentState => state;

  /// 当前播放的媒体源信息
  MediaSourceInfo? get currentMediaSource => _currentMediaSource;

  /// 当前播放的媒体项 ID
  String? get currentItemId => state.itemId;

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
      // 位置继续前进说明播放已恢复，此前那次失败不该再遮挡画面
      final resumed = state.hasError && pos > state.position;
      // 缓冲段随位置一起刷新，共用同一次 state 写入，避免额外重建
      state = state.copyWith(
        position: pos,
        bufferedPosition: _engine.bufferedPosition,
      );
      if (resumed) clearError();
    }));

    // 总时长
    _subscriptions.add(_engine.durationStream.listen((dur) {
      if (!mounted) return;
      // 元数据时长优先：转码流上报的时长常不准确
      final effective = _metadataDuration ?? dur;
      if (effective <= Duration.zero) return;
      state = state.copyWith(duration: effective);
    }));

    // 缓冲状态
    _subscriptions.add(_engine.bufferingStream.listen((buffering) {
      if (!mounted) return;
      _setBuffering(buffering);
    }));

    // 播放完成时刷新轨道列表 + 触发回调
    _subscriptions.add(_engine.completionStream.listen((_) {
      if (!mounted) return;
      _syncTracks();
      // 触发播放完成回调
      onPlaybackComplete?.call();
    }));

    // 轨道就绪通知：media_kit 是在媒体加载后**异步**发现轨道的，
    // 不订阅此流则 UI 的音轨/字幕菜单会一直停留在空列表
    _subscriptions.add(_engine.tracksStream.listen((_) {
      if (!mounted) return;
      _syncTracks();
    }));

    // 定时同步轨道信息（引擎内部更新后刷新到 UI）
    _syncTracks();
  }

  /// 同步引擎的轨道信息到 UI 状态
  void _syncTracks() {
    if (!mounted) return;
    final audioTracks = _engine.audioTracks;
    final subtitleTracks = _effectiveSubtitleTracks;
    if (audioTracks.isNotEmpty || subtitleTracks.isNotEmpty) {
      state = state.copyWith(
        audioTracks: audioTracks,
        subtitleTracks: subtitleTracks,
        currentAudioTrack: _engine.currentAudioTrackIndex,
        currentSubtitleTrack: _engine.currentSubtitleTrackIndex,
      );
    }
  }

  /// 写入缓冲态，并在缓冲期间轮询缓冲进度。
  ///
  /// 缓冲时播放位置不再前进，positionStream 随之停摆，
  /// 只靠引擎的布尔事件无法让缓冲段与百分比动起来，故短时轮询。
  void _setBuffering(bool buffering) {
    if (!mounted) return;
    state = state.copyWith(
      isBuffering: buffering,
      bufferingPercent: _engine.bufferingPercent,
      bufferedPosition: _engine.bufferedPosition,
    );

    _bufferPollTimer?.cancel();
    if (!buffering) return;
    _bufferPollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) return;
      state = state.copyWith(
        bufferingPercent: _engine.bufferingPercent,
        bufferedPosition: _engine.bufferedPosition,
      );
    });
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

      // ── 第 1 步：获取完整播放信息 ──
      final playbackInfo = await _api.getPlaybackInfoFull(
        itemId,
        serverUrl: serverUrl,
        token: token,
        userId: userId,
      );

      final mediaSourceId = playbackInfo.mediaSources.isNotEmpty
          ? playbackInfo.mediaSources.first.id
          : '';
      final playSessionId = playbackInfo.playSessionId;

      state = state.copyWith(
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
      );

      // ── 第 2 步：通过 PlaybackStrategy 决定流 URL ──
      String streamUrl;
      PlayMode? playMode;
      String? playModeReason;

      try {
        final mediaSource = playbackInfo.mediaSources.first;
        _currentMediaSource = mediaSource;
        // 元数据时长是权威值，先写入 state，
        // 避免 UI 在引擎上报前先显示 0:00 再跳变
        _metadataDuration = mediaSource.runTime;
        if (_metadataDuration != null) {
          state = state.copyWith(duration: _metadataDuration!);
        }
        // 收集外挂字幕：转码流不携带文本字幕时需要靠它们
        _externalSubtitles = mediaSource.mediaStreams
            .where((s) => s.isSubtitle && s.deliveryUrl.isNotEmpty)
            .toList();
        final decision = PlaybackStrategy.auto(mediaSource);
        streamUrl = decision.streamUrl;
        playMode = decision.mode;
        playModeReason = decision.reason;
      } catch (_) {
        // Strategy 失败时，回退到原有的直连播放逻辑
        streamUrl = await _api.getVideoStreamUrl(
          serverUrl: serverUrl,
          token: token,
          itemId: itemId,
        );
        playMode = PlayMode.directPlay;
        playModeReason = 'Fallback: direct play';
      }

      // 决策为直连时当前地址即可复用，省去一次额外请求；
      // 决策为转码时置空，待切回"原始画质"再按需拉取
      _directPlayUrl = playMode == PlayMode.directPlay ? streamUrl : null;

      state = state.copyWith(
        streamUrl: streamUrl,
        currentPlayMode: playMode,
        playModeReason: playModeReason,
      );

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

  /// 切换画质
  Future<void> switchQuality({
    required String itemId,
    required PlayMode mode,
    int? maxBitrate,
    int? maxHeight,
  }) async {
    final currentPosition = state.position;

    String streamUrl;
    if (mode == PlayMode.transcode && maxBitrate != null) {
      streamUrl = await _api.getTranscodeStreamUrl(
        itemId,
        maxBitrate: maxBitrate,
        maxHeight: maxHeight,
        serverUrl: serverUrl,
        token: token,
      );
    } else {
      // 优先使用 Emby 在 PlaybackInfo 中下发的权威直连地址，
      // 它已带上正确的容器与全部必要参数。
      // 退路 getVideoStreamUrl 是手工拼接、Container 默认写死 mp4，
      // 对 mkv/avi 等文件在 Static=true 下 Emby 无法正确响应，
      // 这正是"直接播放有问题"的成因
      final authoritative = _currentMediaSource?.directStreamUrl ?? '';
      if (authoritative.isNotEmpty) {
        _directPlayUrl ??= authoritative;
      } else {
        final container = _currentMediaSource?.container ?? '';
        _directPlayUrl ??= await _api.getVideoStreamUrl(
          serverUrl: serverUrl,
          token: token,
          itemId: itemId,
          // 用媒体源的真实容器，而非写死的 mp4
          container: container.isNotEmpty ? container : 'mp4',
        );
      }
      streamUrl = _directPlayUrl!;
    }

    if (streamUrl.isEmpty) return;

    // 获取直连地址可能触发网络请求，其间用户可能已退出播放页
    if (!mounted) return;

    await _reopenStream(streamUrl, resumeAt: currentPosition);

    // 上述 await 期间控制器可能已被销毁，写入已销毁的 StateNotifier 会抛异常
    if (!mounted) return;

    state = state.copyWith(
      currentPlayMode: mode,
      playModeReason: mode == PlayMode.transcode ? '画质: ${maxHeight ?? "auto"}p' : 'Direct Play',
    );
  }

  /// 以当前进度重新打开指定流地址。
  ///
  /// 切画质与失败重试共用：两者都是「停引擎 → 换地址重开 → 回到原位置」，
  /// 分写两份很容易只修一处（例如漏掉 seek，或漏掉清除上一次的错误）。
  Future<void> _reopenStream(
    String streamUrl, {
    Duration resumeAt = Duration.zero,
  }) async {
    if (!mounted) return;

    // 重新发起播放即视为放弃上一次的失败结果，否则错误卡片会盖住新画面
    clearError();

    try {
      await _engine.stop();
      await _engine.open(streamUrl, headers: {
        'Authorization': 'MediaBrowser Token="$token"',
        'X-Emby-Token': token,
      });

      if (resumeAt.inMilliseconds > 0) {
        // open 刚返回时引擎尚未就绪，立刻 seek 会被忽略
        await Future.delayed(const Duration(milliseconds: 500));
        await _engine.seek(resumeAt);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  /// 重试当前播放：不改画质与播放模式，用当前流地址从原位置重开。
  ///
  /// 供播放失败后的「重试」动作使用。不复用 loadAndPlay，
  /// 那会重新走一遍 PlaybackInfo 决策并重置进度上报，代价远大于重开流。
  Future<void> retry() async {
    final url = state.streamUrl ?? _directPlayUrl;
    if (url == null || url.isEmpty) return;
    await _reopenStream(url, resumeAt: state.position);
    if (!mounted) return;
    _resetControlsHideTimer();
  }

  /// 清除错误提示。无错误时不写入 state，避免无谓的重建。
  void clearError() {
    if (!mounted || !state.hasError) return;
    state = state.copyWith(error: null);
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
      _volumeBeforeMute = state.volume;
      setVolume(0);
    } else {
      // 恢复静音前的音量，而非写死 1.0 覆盖用户的音量设置
      setVolume(_volumeBeforeMute > 0 ? _volumeBeforeMute : 1.0);
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
    if (index >= 0 && _useExternalSubtitles) {
      await _selectExternalSubtitle(index);
    } else {
      await _engine.setSubtitleTrack(index);
      if (!mounted) return;
      state = state.copyWith(currentSubtitleTrack: index);
    }
    _resetControlsHideTimer();
  }

  /// 加载 Emby 以 External 方式提供的字幕。
  ///
  /// 转码流无法内嵌文本字幕，引擎侧因此发现不到任何字幕轨道，
  /// 只能由客户端自行拉取字幕文件交给播放器。
  Future<void> _selectExternalSubtitle(int index) async {
    if (index >= _externalSubtitles.length) return;

    final stream = _externalSubtitles[index];
    final url = _resolveEmbyUrl(stream.deliveryUrl);
    if (url == null) return;

    await _engine.loadExternalSubtitle(
      url,
      title: stream.displayTitle.isNotEmpty ? stream.displayTitle : null,
      language: stream.language.isNotEmpty ? stream.language : null,
    );
    if (!mounted) return;
    state = state.copyWith(currentSubtitleTrack: index);
  }

  /// Emby 的 DeliveryUrl 可能是相对路径，需拼上真实服务器地址。
  ///
  /// 注意 [serverUrl] 存的是 Emby 服务器地址而非本地代理地址，
  /// 播放器需要能直接访问该地址取回字幕文件。
  String? _resolveEmbyUrl(String deliveryUrl) {
    if (deliveryUrl.isEmpty) return null;
    if (deliveryUrl.startsWith('http://') ||
        deliveryUrl.startsWith('https://')) {
      return deliveryUrl;
    }
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return base + (deliveryUrl.startsWith('/') ? deliveryUrl : '/$deliveryUrl');
  }

  /// Load an external subtitle from a URL (for subtitles with DeliveryMethod == 'External' ).
  Future<void> loadExternalSubtitle(String url, {String? title, String? language}) async {
    await _engine.loadExternalSubtitle(url, title: title, language: language);
    state = state.copyWith(currentSubtitleTrack: -2);
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
    _bufferPollTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _engine.dispose();
    super.dispose();
  }
}
