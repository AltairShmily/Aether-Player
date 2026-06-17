import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// 设置服务 Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// 播放引擎类型状态管理
class PlayerEngineNotifier extends StateNotifier<PlayerEngineType> {
  final SettingsService _settings;

  PlayerEngineNotifier(this._settings) : super(PlayerEngineType.mediaKit);

  /// 从持久化存储加载
  Future<void> load() async {
    state = await _settings.getPlayerEngine();
  }

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
