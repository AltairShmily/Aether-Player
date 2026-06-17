import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'i18n/strings.g.dart';
import 'services/backend_service.dart';

/// Go 后端服务全局实例
final backendServiceProvider = Provider<BackendService>((ref) {
  final service = BackendService();
  ref.onDispose(() => service.stop());
  return service;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  // 启动 Go 后端
  final backend = BackendService();
  bool backendReady = false;

  try {
    await backend.start();
    backendReady = true;
    debugPrint('[main] Go backend started on port ${backend.port}');
  } catch (e) {
    debugPrint('[main] Go backend failed to start: $e');
    // 后端启动失败不阻止应用运行
    // 用户仍可看到错误提示，或使用纯前端功能
  }

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          backendServiceProvider.overrideWithValue(backend),
        ],
        child: AetherApp(backendReady: backendReady),
      ),
    ),
  );
}
