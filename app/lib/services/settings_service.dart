import 'package:shared_preferences/shared_preferences.dart';

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
}
