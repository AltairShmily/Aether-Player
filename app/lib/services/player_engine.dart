import 'dart:async';

/// 播放器状态枚举
enum PlayerState {
  /// 空闲（未加载媒体）
  idle,

  /// 正在播放
  playing,

  /// 已暂停
  paused,

  /// 正在缓冲
  buffering,

  /// 已停止
  stopped,

  /// 出错
  error,
}

/// 媒体类型枚举
enum MediaType { video, audio }

/// 音轨 / 字幕轨道信息
/// 独立定义以避免循环依赖
class TrackInfo {
  /// 轨道序号
  final int index;

  /// 语言代码（如 'zh', 'en'）
  final String language;

  /// 轨道标题
  final String title;

  /// 编码格式（如 'aac', 'h264'）
  final String codec;

  /// 轨道类型：'audio' 或 'subtitle'
  final String type;

  const TrackInfo({
    required this.index,
    this.language = '',
    this.title = '',
    this.codec = '',
    required this.type,
  });

  @override
  String toString() =>
      'TrackInfo(index: $index, lang: $language, title: $title, codec: $codec, type: $type)';
}

/// 播放器引擎抽象接口
///
/// 定义了播放器的核心功能，具体实现由各引擎提供。
/// 上层 UI / Provider 只依赖此接口，与具体引擎解耦。
abstract class PlayerEngine {
  // ── 状态流 ──────────────────────────────────────────────────────

  /// 播放器状态变化流
  Stream<PlayerState> get stateStream;

  /// 播放位置变化流
  Stream<Duration> get positionStream;

  /// 媒体总时长变化流
  Stream<Duration> get durationStream;

  /// 缓冲状态变化流
  Stream<bool> get bufferingStream;

  /// 播放完成事件流
  Stream<void> get completionStream;

  // ── 状态属性 ──────────────────────────────────────────────────

  /// 当前播放器状态
  PlayerState get currentState;

  /// 当前播放位置
  Duration get position;

  /// 媒体总时长
  Duration get duration;

  /// 是否正在播放
  bool get isPlaying;

  /// 是否正在缓冲
  bool get isBuffering;

  /// 音量（0.0 - 1.0）
  double get volume;

  /// 播放速度（0.5, 1.0, 1.5, 2.0 等）
  double get playbackSpeed;

  /// 可用音轨列表
  List<TrackInfo> get audioTracks;

  /// 可用字幕轨道列表
  List<TrackInfo> get subtitleTracks;

  /// 当前选中的音轨索引
  int get currentAudioTrackIndex;

  /// 当前选中的字幕轨道索引（-1 = 关闭）
  int get currentSubtitleTrackIndex;

  // ── 控制方法 ──────────────────────────────────────────────────

  /// 打开媒体资源进行播放
  Future<void> open(String url, {Map<String, String> headers = const {}});

  /// 开始播放
  Future<void> play();

  /// 暂停播放
  Future<void> pause();

  /// 切换播放 / 暂停状态
  Future<void> togglePlay();

  /// 跳转到指定位置
  Future<void> seek(Duration position);

  /// 设置音量（0.0 - 1.0）
  Future<void> setVolume(double volume);

  /// 设置播放速度
  Future<void> setPlaybackSpeed(double speed);

  /// 设置音轨（按索引）
  Future<void> setAudioTrack(int index);

  /// 设置字幕轨道（-1 = 关闭）
  Future<void> setSubtitleTrack(int index);

  /// 停止播放
  Future<void> stop();

  /// 释放所有资源
  Future<void> dispose();
}
