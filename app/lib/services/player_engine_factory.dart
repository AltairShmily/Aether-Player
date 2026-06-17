import 'player_engine.dart';
import 'mpv_engine.dart';
import 'settings_service.dart';
import 'package:flutter/foundation.dart';

// 延迟导入原生引擎，避免在不支持的平台上崩溃
import 'native_engine.dart' as native;

/// 播放器引擎工厂
///
/// 根据用户设置创建对应的播放引擎实例。
/// 支持 media_kit 和原生 C++ FFI 两种后端。
class PlayerEngineFactory {
  /// 根据引擎类型创建对应的播放器引擎实例
  ///
  /// 如果原生引擎不可用，会自动回退到 media_kit。
  static PlayerEngine create(PlayerEngineType type) {
    switch (type) {
      case PlayerEngineType.mediaKit:
        return MpvEngine();
      case PlayerEngineType.nativeFfi:
        try {
          return native.NativeFfiEngine();
        } catch (e) {
          // 原生引擎不可用时回退到 media_kit
          debugPrint('[PlayerEngineFactory] Native engine unavailable, '
              'falling back to media_kit: $e');
          return MpvEngine();
        }
    }
  }

  /// 创建默认引擎（media_kit）
  static PlayerEngine createDefault() => MpvEngine();
}
