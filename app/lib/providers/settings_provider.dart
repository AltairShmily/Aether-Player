import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// 设置服务 Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// 播放引擎类型状态管理
class PlayerEngineNotifier extends StateNotifier<PlayerEngineType> {
  final SettingsService _settings;

  /// [initial] 由 main() 在启动时从持久化存储读取后注入，
  /// 使首帧即为正确的引擎类型，避免默认值闪烁。
  PlayerEngineNotifier(this._settings, {PlayerEngineType? initial})
      : super(initial ?? PlayerEngineType.mediaKit);

  /// 切换播放引擎
  Future<void> setEngine(PlayerEngineType type) async {
    state = type;
    await _settings.setPlayerEngine(type);
  }
}

/// 播放引擎类型 Provider
final playerEngineProvider =
    StateNotifierProvider<PlayerEngineNotifier, PlayerEngineType>((ref) {
  return PlayerEngineNotifier(ref.read(settingsServiceProvider));
});
