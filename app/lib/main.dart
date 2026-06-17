import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // 捕获未处理的异步异常（如 google_fonts 加载失败）
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 设置 Flutter 错误处理
    FlutterError.onError = (details) {
      debugPrint('[FlutterError] ${details.exception}');
      // 不调用 FlutterError.presentError，避免崩溃
    };

    LocaleSettings.useDeviceLocale();

    // 配置 google_fonts — 启用运行时获取
    GoogleFonts.config.allowRuntimeFetching = true;

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
  }, (error, stackTrace) {
    debugPrint('[ZoneError] $error');
    // 捕获未处理的异步异常，避免应用崩溃
  });
}
