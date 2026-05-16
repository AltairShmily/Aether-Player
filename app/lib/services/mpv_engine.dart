import 'dart:async';

import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

import 'player_engine.dart';

/// 基于 media_kit (MPV) 的播放器引擎实现
///
/// 使用 [mk.Player] 作为底层播放后端，将 media_kit 的事件流
/// 桥接到本应用自定义的 [PlayerEngine] 接口。
class MpvEngine implements PlayerEngine {
  late final mk.Player _player;

  // ── 流控制器 ──────────────────────────────────────────────────
  // 用于将 media_kit 的流桥接到我们的接口流
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _bufferingController =
      StreamController<bool>.broadcast();
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();

  // ── 缓存状态 ──────────────────────────────────────────────────
  PlayerState _currentState = PlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  List<TrackInfo> _audioTracks = [];
  List<TrackInfo> _subtitleTracks = [];
  int _currentAudioTrackIndex = -1;
  int _currentSubtitleTrackIndex = -1;

  // 所有流订阅，便于 dispose 时一次性取消
  final List<StreamSubscription> _subscriptions = [];

  // ── 构造 ──────────────────────────────────────────────────────

  /// 暴露底层 media_kit Player 给 UI（Video widget 需要）
  mk.Player get videoPlayer => _player;

  /// 创建 media_kit VideoController（供 Video widget 使用）
  VideoController get videoController => VideoController(_player);

  /// 创建 MPV 播放器引擎实例
  MpvEngine() {
    // 初始化 media_kit 运行时
    mk.MediaKit.ensureInitialized();

    // 创建底层播放器
    _player = mk.Player();

    // 监听播放 / 暂停状态
    _subscriptions.add(_player.stream.playing.listen((playing) {
      _updateState(playing: playing);
    }));

    // 监听播放完成
    _subscriptions.add(_player.stream.completed.listen((completed) {
      if (completed) {
        _completionController.add(null);
        _currentState = PlayerState.stopped;
        _stateController.add(_currentState);
      }
    }));

    // 监听播放位置
    _subscriptions.add(_player.stream.position.listen((pos) {
      _position = pos;
      _positionController.add(pos);
    }));

    // 监听媒体时长
    _subscriptions.add(_player.stream.duration.listen((dur) {
      _duration = dur;
      _durationController.add(dur);
    }));

    // 监听缓冲状态
    _subscriptions.add(_player.stream.buffering.listen((buffering) {
      _isBuffering = buffering;
      _bufferingController.add(buffering);
      _updateState(buffering: buffering);
    }));

    // 监听音量变化（media_kit 0-100，我们 0-1）
    _subscriptions.add(_player.stream.volume.listen((vol) {
      _volume = vol / 100.0;
    }));

    // 监听播放速度变化
    _subscriptions.add(_player.stream.rate.listen((rate) {
      _playbackSpeed = rate;
    }));

    // 监听可用轨道列表变化
    _subscriptions.add(_player.stream.tracks.listen((tracks) {
      _updateTracks(tracks);
    }));

    // 监听当前选中轨道变化
    _subscriptions.add(_player.stream.track.listen((track) {
      _updateCurrentTrackIndices(track);
    }));
  }

  // ── 内部辅助方法 ──────────────────────────────────────────────

  /// 根据 playing / buffering 标志更新内部状态并广播
  void _updateState({bool? playing, bool? buffering}) {
    final isPlaying = playing ?? _player.state.playing;
    final isBufferingValue = buffering ?? _player.state.buffering;

    if (isBufferingValue) {
      _currentState = PlayerState.buffering;
    } else if (isPlaying) {
      _currentState = PlayerState.playing;
    } else if (_currentState == PlayerState.playing ||
        _currentState == PlayerState.buffering) {
      _currentState = PlayerState.paused;
    }
    _stateController.add(_currentState);
  }

  /// 从 media_kit Tracks 更新音轨 / 字幕列表
  void _updateTracks(mk.Tracks tracks) {
    // 过滤掉 'auto' 和 'no' 伪轨道
    final realAudio = tracks.audio
        .where((t) => t.id != 'auto' && t.id != 'no')
        .toList();
    _audioTracks = realAudio.asMap().entries.map((entry) {
      final track = entry.value;
      return TrackInfo(
        index: entry.key,
        language: track.language ?? '',
        title: track.title ?? '',
        codec: track.codec ?? '',
        type: 'audio',
      );
    }).toList();

    final realSubtitle = tracks.subtitle
        .where((t) => t.id != 'auto' && t.id != 'no')
        .toList();
    _subtitleTracks = realSubtitle.asMap().entries.map((entry) {
      final track = entry.value;
      return TrackInfo(
        index: entry.key,
        language: track.language ?? '',
        title: track.title ?? '',
        codec: track.codec ?? '',
        type: 'subtitle',
      );
    }).toList();
  }

  /// 根据当前选中轨道更新索引
  void _updateCurrentTrackIndices(mk.Track track) {
    // ── 音轨 ──
    final currentAudio = track.audio;
    if (currentAudio.id != 'auto' && currentAudio.id != 'no') {
      // 在完整列表中找到其位置，再映射到过滤后的列表
      final rawIndex = _player.state.tracks.audio.indexOf(currentAudio);
      // 前两个是 auto/no，所以 realIndex = rawIndex - 2
      _currentAudioTrackIndex = rawIndex >= 2 ? rawIndex - 2 : -1;
    } else {
      _currentAudioTrackIndex = -1;
    }

    // ── 字幕 ──
    final currentSubtitle = track.subtitle;
    if (currentSubtitle.id != 'no') {
      final rawIndex = _player.state.tracks.subtitle.indexOf(currentSubtitle);
      _currentSubtitleTrackIndex = rawIndex >= 2 ? rawIndex - 2 : -1;
    } else {
      _currentSubtitleTrackIndex = -1;
    }
  }

  // ── 状态流 ────────────────────────────────────────────────────

  @override
  Stream<PlayerState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<bool> get bufferingStream => _bufferingController.stream;

  @override
  Stream<void> get completionStream => _completionController.stream;

  // ── 状态属性 ──────────────────────────────────────────────────

  @override
  PlayerState get currentState => _currentState;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  bool get isPlaying => _player.state.playing;

  @override
  bool get isBuffering => _isBuffering;

  @override
  double get volume => _volume;

  @override
  double get playbackSpeed => _playbackSpeed;

  @override
  List<TrackInfo> get audioTracks => List.unmodifiable(_audioTracks);

  @override
  List<TrackInfo> get subtitleTracks => List.unmodifiable(_subtitleTracks);

  @override
  int get currentAudioTrackIndex => _currentAudioTrackIndex;

  @override
  int get currentSubtitleTrackIndex => _currentSubtitleTrackIndex;

  // ── 控制方法 ──────────────────────────────────────────────────

  @override
  Future<void> open(String url, {Map<String, String> headers = const {}}) async {
    _currentState = PlayerState.buffering;
    _stateController.add(_currentState);
    await _player.open(mk.Media(url, httpHeaders: headers));
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> togglePlay() async {
    await _player.playOrPause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    // media_kit 使用 0-100 范围
    await _player.setVolume(_volume * 100.0);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    // media_kit 使用 setRate
    await _player.setRate(speed);
  }

  @override
  Future<void> setAudioTrack(int index) async {
    if (index < 0 || index >= _audioTracks.length) return;
    final tracks = _player.state.tracks;
    // 过滤后的索引 = media_kit 完整列表索引 - 2（跳过 auto / no）
    final rawIndex = index + 2;
    if (rawIndex < tracks.audio.length) {
      await _player.setAudioTrack(tracks.audio[rawIndex]);
      _currentAudioTrackIndex = index;
    }
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    if (index == -1) {
      // 关闭字幕
      await _player.setSubtitleTrack(mk.SubtitleTrack.no());
      _currentSubtitleTrackIndex = -1;
      return;
    }

    if (index < 0 || index >= _subtitleTracks.length) return;
    final tracks = _player.state.tracks;
    final rawIndex = index + 2;
    if (rawIndex < tracks.subtitle.length) {
      await _player.setSubtitleTrack(tracks.subtitle[rawIndex]);
      _currentSubtitleTrackIndex = index;
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentState = PlayerState.stopped;
    _stateController.add(_currentState);
    _position = Duration.zero;
    _duration = Duration.zero;
    _positionController.add(_position);
    _durationController.add(_duration);
  }

  @override
  Future<void> dispose() async {
    // 取消所有流订阅
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    // 关闭所有流控制器
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferingController.close();
    await _completionController.close();

    // 释放底层播放器资源
    await _player.dispose();
  }
}
