import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'player_engine.dart';

// ══════════════════════════════════════════════════════════════════
//  C 函数签名定义
// ══════════════════════════════════════════════════════════════════

// 回调函数类型
typedef _StateCallbackC = Void Function(Int32 state);
typedef _PositionCallbackC = Void Function(Double seconds);
typedef _DurationCallbackC = Void Function(Double seconds);
typedef _BufferingCallbackC = Void Function(Int32 buffering);
typedef _CompletionCallbackC = Void Function();

typedef _StateCallbackDart = void Function(int state);
typedef _PositionCallbackDart = void Function(double seconds);
typedef _DurationCallbackDart = void Function(double seconds);
typedef _BufferingCallbackDart = void Function(int buffering);
typedef _CompletionCallbackDart = void Function();

// 引擎函数签名
typedef _EngineCreateC = Pointer<Void> Function();
typedef _EngineCreateDart = Pointer<Void> Function();

typedef _EngineDestroyC = Void Function(Pointer<Void> handle);
typedef _EngineDestroyDart = void Function(Pointer<Void> handle);

typedef _EngineInitC = Int32 Function(Pointer<Void> handle);
typedef _EngineInitDart = int Function(Pointer<Void> handle);

typedef _EngineOpenC = Int32 Function(
    Pointer<Void> handle, Pointer<Utf8> url, Pointer<Utf8> headers);
typedef _EngineOpenDart = int Function(
    Pointer<Void> handle, Pointer<Utf8> url, Pointer<Utf8> headers);

typedef _EngineVoidC = Void Function(Pointer<Void> handle);
typedef _EngineVoidDart = void Function(Pointer<Void> handle);

typedef _EngineSeekC = Void Function(Pointer<Void> handle, Double pos);
typedef _EngineSeekDart = void Function(Pointer<Void> handle, double pos);

typedef _EngineSetDoubleC = Void Function(Pointer<Void> handle, Double val);
typedef _EngineSetDoubleDart = void Function(Pointer<Void> handle, double val);

typedef _EngineSetIntC = Void Function(Pointer<Void> handle, Int32 val);
typedef _EngineSetIntDart = void Function(Pointer<Void> handle, int val);

typedef _EngineGetDoubleC = Double Function(Pointer<Void> handle);
typedef _EngineGetDoubleDart = double Function(Pointer<Void> handle);

typedef _EngineGetIntC = Int32 Function(Pointer<Void> handle);
typedef _EngineGetIntDart = int Function(Pointer<Void> handle);

typedef _EngineSetCallbackC = Void Function(
    Pointer<Void> handle, Pointer<NativeFunction<_StateCallbackC>> fn);
typedef _EngineSetCallbackDart = void Function(
    Pointer<Void> handle, Pointer<NativeFunction<_StateCallbackC>> fn);

// ══════════════════════════════════════════════════════════════════
//  NativeFfiEngine — 基于 C++ FFI 的播放器引擎实现
// ══════════════════════════════════════════════════════════════════

/// 基于 dart:ffi 的原生播放器引擎
///
/// 通过 FFI 调用 C++ 封装的 libmpv，绕过 media_kit。
/// 实现与 [MpvEngine] 相同的 [PlayerEngine] 接口。
class NativeFfiEngine implements PlayerEngine {
  // ── 动态库 ──
  late final DynamicLibrary _lib;
  late final Pointer<Void> _handle;

  // ── 函数绑定 ──
  late final _EngineCreateDart _create;
  late final _EngineDestroyDart _destroy;
  late final _EngineInitDart _init;
  late final _EngineOpenDart _open;
  late final _EngineVoidDart _play;
  late final _EngineVoidDart _pause;
  late final _EngineVoidDart _togglePlay;
  late final _EngineSeekDart _seek;
  late final _EngineVoidDart _stop;
  late final _EngineSetDoubleDart _setVolume;
  late final _EngineSetDoubleDart _setPlaybackSpeed;
  late final _EngineSetIntDart _setAudioTrack;
  late final _EngineSetIntDart _setSubtitleTrack;
  late final _EngineGetDoubleDart _getPosition;
  late final _EngineGetDoubleDart _getDuration;
  late final _EngineGetDoubleDart _getVolume;
  late final _EngineGetDoubleDart _getPlaybackSpeed;
  late final _EngineGetIntDart _getState;
  late final _EngineGetIntDart _isPlaying;
  late final _EngineGetIntDart _isBuffering;

  // ── 流控制器 ──
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

  // ── 缓存状态 ──
  PlayerState _currentState = PlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBufferingState = false;
  double _volume = 100.0; // 原生使用 0-100
  double _playbackSpeed = 1.0;
  List<TrackInfo> _audioTracks = [];
  List<TrackInfo> _subtitleTracks = [];
  int _currentAudioTrackIndex = -1;
  int _currentSubtitleTrackIndex = -1;

  // 回调持有（防止 GC 回收）
  // ignore: unused_field
  late final Pointer<NativeFunction<_StateCallbackC>> _stateCallbackPtr;
  // ignore: unused_field
  late final Pointer<NativeFunction<_PositionCallbackC>> _posCallbackPtr;
  // ignore: unused_field
  late final Pointer<NativeFunction<_DurationCallbackC>> _durCallbackPtr;
  // ignore: unused_field
  late final Pointer<NativeFunction<_BufferingCallbackC>> _bufCallbackPtr;
  // ignore: unused_field
  late final Pointer<NativeFunction<_CompletionCallbackC>> _compCallbackPtr;

  // ── 构造 / 初始化 ──

  NativeFfiEngine() {
    // 加载动态库
    _lib = _loadLibrary();

    // 绑定函数
    _create = _lib
        .lookupFunction<_EngineCreateC, _EngineCreateDart>('engine_create');
    _destroy = _lib
        .lookupFunction<_EngineDestroyC, _EngineDestroyDart>('engine_destroy');
    _init = _lib
        .lookupFunction<_EngineInitC, _EngineInitDart>('engine_initialize');
    _open =
        _lib.lookupFunction<_EngineOpenC, _EngineOpenDart>('engine_open');
    _play = _lib.lookupFunction<_EngineVoidC, _EngineVoidDart>('engine_play');
    _pause =
        _lib.lookupFunction<_EngineVoidC, _EngineVoidDart>('engine_pause');
    _togglePlay = _lib
        .lookupFunction<_EngineVoidC, _EngineVoidDart>('engine_toggle_play');
    _seek = _lib.lookupFunction<_EngineSeekC, _EngineSeekDart>('engine_seek');
    _stop = _lib.lookupFunction<_EngineVoidC, _EngineVoidDart>('engine_stop');
    _setVolume = _lib.lookupFunction<_EngineSetDoubleC, _EngineSetDoubleDart>(
        'engine_set_volume');
    _setPlaybackSpeed = _lib
        .lookupFunction<_EngineSetDoubleC, _EngineSetDoubleDart>(
            'engine_set_playback_speed');
    _setAudioTrack = _lib
        .lookupFunction<_EngineSetIntC, _EngineSetIntDart>(
            'engine_set_audio_track');
    _setSubtitleTrack = _lib
        .lookupFunction<_EngineSetIntC, _EngineSetIntDart>(
            'engine_set_subtitle_track');
    _getPosition = _lib.lookupFunction<_EngineGetDoubleC, _EngineGetDoubleDart>(
        'engine_get_position');
    _getDuration = _lib.lookupFunction<_EngineGetDoubleC, _EngineGetDoubleDart>(
        'engine_get_duration');
    _getVolume = _lib.lookupFunction<_EngineGetDoubleC, _EngineGetDoubleDart>(
        'engine_get_volume');
    _getPlaybackSpeed = _lib
        .lookupFunction<_EngineGetDoubleC, _EngineGetDoubleDart>(
            'engine_get_playback_speed');
    _getState = _lib
        .lookupFunction<_EngineGetIntC, _EngineGetIntDart>('engine_get_state');
    _isPlaying = _lib
        .lookupFunction<_EngineGetIntC, _EngineGetIntDart>('engine_is_playing');
    _isBuffering = _lib
        .lookupFunction<_EngineGetIntC, _EngineGetIntDart>(
            'engine_is_buffering');

    // 创建引擎实例
    _handle = _create();

    // 初始化
    final result = _init(_handle);
    if (result != 0) {
      throw Exception('Failed to initialize native engine');
    }

    // 注册回调
    _setupCallbacks();

    // 设置全局实例引用（FFI 静态回调需要）
    _instance = this;
  }

  /// 加载平台对应的动态库
  DynamicLibrary _loadLibrary() {
    if (Platform.isLinux) {
      // 开发时从构建目录加载，发布时从系统路径加载
      const libName = 'libaether_engine.so';
      // 尝试几个可能的路径
      final paths = [
        'engine/build/$libName',
        '../engine/build/$libName',
        libName,
      ];
      for (final path in paths) {
        try {
          return DynamicLibrary.open(path);
        } catch (_) {
          continue;
        }
      }
      return DynamicLibrary.open(libName);
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('aether_engine.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libaether_engine.dylib');
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libaether_engine.so');
    }
    throw UnsupportedError('Platform not supported for native engine');
  }

  /// 设置 C++ → Dart 回调桥接
  void _setupCallbacks() {
    // State callback
    _stateCallbackPtr = Pointer.fromFunction<_StateCallbackC>(_onStateNative);
    final setStateFn = _lib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<NativeFunction<_StateCallbackC>>),
        void Function(Pointer<Void>,
            Pointer<NativeFunction<_StateCallbackC>>)>("engine_set_state_callback");
    setStateFn(_handle, _stateCallbackPtr);

    // Position callback
    _posCallbackPtr =
        Pointer.fromFunction<_PositionCallbackC>(_onPositionNative);
    final setPosFn = _lib.lookupFunction<
        Void Function(
            Pointer<Void>, Pointer<NativeFunction<_PositionCallbackC>>),
        void Function(Pointer<Void>,
            Pointer<NativeFunction<_PositionCallbackC>>)>(
        "engine_set_position_callback");
    setPosFn(_handle, _posCallbackPtr);

    // Duration callback
    _durCallbackPtr =
        Pointer.fromFunction<_DurationCallbackC>(_onDurationNative);
    final setDurFn = _lib.lookupFunction<
        Void Function(
            Pointer<Void>, Pointer<NativeFunction<_DurationCallbackC>>),
        void Function(Pointer<Void>,
            Pointer<NativeFunction<_DurationCallbackC>>)>(
        "engine_set_duration_callback");
    setDurFn(_handle, _durCallbackPtr);

    // Buffering callback
    _bufCallbackPtr =
        Pointer.fromFunction<_BufferingCallbackC>(_onBufferingNative);
    final setBufFn = _lib.lookupFunction<
        Void Function(
            Pointer<Void>, Pointer<NativeFunction<_BufferingCallbackC>>),
        void Function(Pointer<Void>,
            Pointer<NativeFunction<_BufferingCallbackC>>)>(
        "engine_set_buffering_callback");
    setBufFn(_handle, _bufCallbackPtr);

    // Completion callback
    _compCallbackPtr =
        Pointer.fromFunction<_CompletionCallbackC>(_onCompletionNative);
    final setCompFn = _lib.lookupFunction<
        Void Function(
            Pointer<Void>, Pointer<NativeFunction<_CompletionCallbackC>>),
        void Function(Pointer<Void>,
            Pointer<NativeFunction<_CompletionCallbackC>>)>(
        "engine_set_completion_callback");
    setCompFn(_handle, _compCallbackPtr);
  }

  // ── 静态回调（C 端调用） ──
  // 这些必须是顶层/静态函数，通过全局实例转发到流控制器

  // 使用 Dart 侧的静态回调 -> 实例方法转发
  // 注意：FFI 回调函数必须是 static 或顶层
  // 我们使用单例模式或 Isolate 端口来桥接

  // 由于 dart:ffi 回调必须是静态/顶层，
  // 我们使用一个简单的全局实例引用
  static NativeFfiEngine? _instance;

  static void _onStateNative(int state) {
    final engine = _instance;
    if (engine == null) return;
    final playerState = PlayerState.values[state.clamp(0, 5)];
    engine._currentState = playerState;
    engine._stateController.add(playerState);
  }

  static void _onPositionNative(double seconds) {
    final engine = _instance;
    if (engine == null) return;
    final dur = Duration(milliseconds: (seconds * 1000).round());
    engine._position = dur;
    engine._positionController.add(dur);
  }

  static void _onDurationNative(double seconds) {
    final engine = _instance;
    if (engine == null) return;
    final dur = Duration(milliseconds: (seconds * 1000).round());
    engine._duration = dur;
    engine._durationController.add(dur);
  }

  static void _onBufferingNative(int buffering) {
    final engine = _instance;
    if (engine == null) return;
    engine._isBufferingState = buffering != 0;
    engine._bufferingController.add(engine._isBufferingState);
  }

  static void _onCompletionNative() {
    final engine = _instance;
    if (engine == null) return;
    engine._currentState = PlayerState.stopped;
    engine._stateController.add(PlayerState.stopped);
    engine._completionController.add(null);
  }

  // ── PlayerEngine 接口实现 ──

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

  @override
  PlayerState get currentState => _currentState;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  bool get isPlaying => _isPlaying(_handle) != 0;

  @override
  bool get isBuffering => _isBufferingState;

  @override
  double get volume => _volume / 100.0; // 转换为 0-1 范围

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

  @override
  Future<void> open(String url,
      {Map<String, String> headers = const {}}) async {
    _currentState = PlayerState.buffering;
    _stateController.add(_currentState);

    final urlPtr = url.toNativeUtf8();

    // 将 headers 转换为 mpv 的 http-header-fields 格式
    // 格式: "Key1: Value1\nKey2: Value2"
    final headerStr =
        headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    final headersPtr = headerStr.toNativeUtf8();

    try {
      _open(_handle, urlPtr, headersPtr);
    } finally {
      calloc.free(urlPtr);
      calloc.free(headersPtr);
    }
  }

  @override
  Future<void> play() async {
    _play(_handle);
  }

  @override
  Future<void> pause() async {
    _pause(_handle);
  }

  @override
  Future<void> togglePlay() async {
    _togglePlay(_handle);
  }

  @override
  Future<void> seek(Duration position) async {
    _seek(_handle, position.inMilliseconds / 1000.0);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = (volume * 100).clamp(0.0, 100.0);
    _setVolume(_handle, _volume);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    _setPlaybackSpeed(_handle, speed);
  }

  @override
  Future<void> setAudioTrack(int index) async {
    _setAudioTrack(_handle, index);
    _currentAudioTrackIndex = index;
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    _setSubtitleTrack(_handle, index);
    _currentSubtitleTrackIndex = index;
  }

  @override
  Future<void> stop() async {
    _stop(_handle);
    _currentState = PlayerState.stopped;
    _stateController.add(_currentState);
    _position = Duration.zero;
    _duration = Duration.zero;
    _positionController.add(_position);
    _durationController.add(_duration);
  }

  @override
  Future<void> dispose() async {
    // 关闭流控制器
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferingController.close();
    await _completionController.close();

    // 销毁引擎
    _destroy(_handle);
    _instance = null;
  }
}
