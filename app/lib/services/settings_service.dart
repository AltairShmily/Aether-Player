import 'package:shared_preferences/shared_preferences.dart';

/// 播放引擎类型
enum PlayerEngineType {
  /// media_kit (libmpv 封装，通过 Dart 包调用)
  mediaKit('media_kit', 'Media Kit (默认)'),

  /// 原生 C++ FFI (直接调用 libmpv)
  nativeFfi('native_ffi', '原生 C++ 引擎');

  const PlayerEngineType(this.key, this.label);

  final String key;
  final String label;

  static PlayerEngineType fromKey(String key) {
    return PlayerEngineType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => PlayerEngineType.mediaKit,
    );
  }
}

/// 设置持久化服务
///
/// 使用 SharedPreferences 存储用户设置
class SettingsService {
  static const _keyAutoPlayNext = 'settings_auto_play_next';
  static const _keyHardwareAcceleration = 'settings_hardware_acceleration';
  static const _keyNoiseTexture = 'settings_noise_texture';
  static const _keyAnimations = 'settings_animations';
  static const _keyRemoteAccess = 'settings_remote_access';
  static const _keyBandwidthLimit = 'settings_bandwidth_limit';
  static const _keyBandwidthLimitValue = 'settings_bandwidth_limit_value';
  static const _keyPlayerEngine = 'settings_player_engine';
  static const _keyAudioPassthrough = 'settings_audio_passthrough';
  static const _keyDefaultAudioLang = 'settings_default_audio_lang';
  static const _keyDefaultSubtitleLang = 'settings_default_subtitle_lang';
  static const _keySubtitleSize = 'settings_subtitle_size';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── 播放设置 ──

  Future<bool> getAutoPlayNext() async {
    final p = await prefs;
    return p.getBool(_keyAutoPlayNext) ?? true;
  }

  Future<void> setAutoPlayNext(bool value) async {
    final p = await prefs;
    await p.setBool(_keyAutoPlayNext, value);
  }

  Future<bool> getHardwareAcceleration() async {
    final p = await prefs;
    return p.getBool(_keyHardwareAcceleration) ?? true;
  }

  Future<void> setHardwareAcceleration(bool value) async {
    final p = await prefs;
    await p.setBool(_keyHardwareAcceleration, value);
  }

  // ── 外观设置 ──

  Future<bool> getNoiseTexture() async {
    final p = await prefs;
    return p.getBool(_keyNoiseTexture) ?? true;
  }

  Future<void> setNoiseTexture(bool value) async {
    final p = await prefs;
    await p.setBool(_keyNoiseTexture, value);
  }

  Future<bool> getAnimations() async {
    final p = await prefs;
    return p.getBool(_keyAnimations) ?? true;
  }

  Future<void> setAnimations(bool value) async {
    final p = await prefs;
    await p.setBool(_keyAnimations, value);
  }

  // ── 网络设置 ──

  Future<bool> getRemoteAccess() async {
    final p = await prefs;
    return p.getBool(_keyRemoteAccess) ?? false;
  }

  Future<void> setRemoteAccess(bool value) async {
    final p = await prefs;
    await p.setBool(_keyRemoteAccess, value);
  }

  Future<String> getBandwidthLimit() async {
    final p = await prefs;
    return p.getString(_keyBandwidthLimit) ?? 'auto';
  }

  Future<void> setBandwidthLimit(String value) async {
    final p = await prefs;
    await p.setString(_keyBandwidthLimit, value);
  }

  // ── 播放引擎设置 ──

  Future<PlayerEngineType> getPlayerEngine() async {
    final p = await prefs;
    final key = p.getString(_keyPlayerEngine) ?? PlayerEngineType.mediaKit.key;
    return PlayerEngineType.fromKey(key);
  }

  Future<void> setPlayerEngine(PlayerEngineType type) async {
    final p = await prefs;
    await p.setString(_keyPlayerEngine, type.key);
  }

  // ── 音频设置 ──

  Future<bool> getAudioPassthrough() async {
    final p = await prefs;
    return p.getBool(_keyAudioPassthrough) ?? false;
  }

  Future<void> setAudioPassthrough(bool value) async {
    final p = await prefs;
    await p.setBool(_keyAudioPassthrough, value);
  }

  Future<String> getDefaultAudioLanguage() async {
    final p = await prefs;
    return p.getString(_keyDefaultAudioLang) ?? 'zh';
  }

  Future<void> setDefaultAudioLanguage(String value) async {
    final p = await prefs;
    await p.setString(_keyDefaultAudioLang, value);
  }

  // ── 字幕设置 ──

  Future<String> getDefaultSubtitleLanguage() async {
    final p = await prefs;
    return p.getString(_keyDefaultSubtitleLang) ?? 'zh';
  }

  Future<void> setDefaultSubtitleLanguage(String value) async {
    final p = await prefs;
    await p.setString(_keyDefaultSubtitleLang, value);
  }

  Future<double> getSubtitleSize() async {
    final p = await prefs;
    return p.getDouble(_keySubtitleSize) ?? 1.0;
  }

  Future<void> setSubtitleSize(double value) async {
    final p = await prefs;
    await p.setDouble(_keySubtitleSize, value);
  }

  // ── 带宽限制（数值） ──

  Future<int> getBandwidthLimitValue() async {
    final p = await prefs;
    return p.getInt(_keyBandwidthLimitValue) ?? 0;
  }

  Future<void> setBandwidthLimitValue(int value) async {
    final p = await prefs;
    await p.setInt(_keyBandwidthLimitValue, value);
  }
}
