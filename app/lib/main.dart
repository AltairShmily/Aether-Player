import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'i18n/strings.g.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/settings_provider.dart';
import 'services/backend_service.dart';
import 'services/error_logger.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

/// Go 后端服务全局实例
final backendServiceProvider = Provider<BackendService>((ref) {
  final service = BackendService();
  ref.onDispose(() => service.stop());
  return service;
});

void main() async {
  // 捕获未处理的异步异常（如 google_fonts 加载失败）
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 初始化错误日志（须在 presentError 恢复前完成）
      await ErrorLogger.init();

      // 设置 Flutter 错误处理
      FlutterError.onError = (details) {
        // presentError 在 debug 下显示红屏，release 下由框架自行静默；
        // 此前故意跳过该调用会使所有框架错误不可见
        FlutterError.presentError(details);
        ErrorLogger.log('FlutterError', details.exception, details.stack);
      };

      // 注册应用生命周期监听，确保退出时清理后端
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

      // 恢复持久化的用户设置。
      // 必须在 runApp 之前完成并作为初始值注入，否则会先渲染默认值再跳变。
      final savedEngine = await SettingsService().getPlayerEngine();
      final savedLocaleTag = await StorageService().getLocale();
      final savedLocale = savedLocaleTag == null
          ? null
          : AppLocale.values
              .where((l) => l.languageTag == savedLocaleTag)
              .firstOrNull;

      if (savedLocale != null) {
        LocaleSettings.setLocale(savedLocale);
      } else {
        LocaleSettings.useDeviceLocale();
      }

      // 配置 google_fonts — 启用运行时获取
      GoogleFonts.config.allowRuntimeFetching = true;

      // 启动 Go 后端
      final backend = BackendService();
      bool backendReady = false;

      try {
        await backend.start();
        backendReady = true;
        debugPrint('[main] Go backend started on port ${backend.port}');
      } catch (e, s) {
        // 后端启动失败会导致全部接口不可用，须落盘以便事后诊断
        await ErrorLogger.log('BackendStart', e, s);
        // 后端启动失败不阻止应用运行
        // 用户仍可看到错误提示，或使用纯前端功能
      }

      runApp(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              backendServiceProvider.overrideWithValue(backend),
              playerEngineProvider.overrideWith(
                (ref) => PlayerEngineNotifier(
                  ref.read(settingsServiceProvider),
                  initial: savedEngine,
                ),
              ),
              localeProvider.overrideWith(
                (ref) => LocaleNotifier(
                  ref.read(storageServiceProvider),
                  initial: savedLocale ?? LocaleSettings.currentLocale,
                ),
              ),
            ],
            child: AetherApp(backendReady: backendReady),
          ),
        ),
      );
    },
    (error, stackTrace) {
      // 落盘而非仅 debugPrint：release 构建下控制台输出无人观察
      ErrorLogger.log('ZoneError', error, stackTrace);
    },
  );
}

/// 应用生命周期监听器
///
/// 桌面端窗口关闭时，Flutter 引擎可能不会正常 dispose Provider。
/// 通过监听生命周期事件，在 detached 状态下强制清理后端进程。
/// 主要依赖 BackendService 中的 OS 信号处理器（SIGTERM/SIGINT），
/// 此处作为额外的安全网。
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      debugPrint('[Lifecycle] App detached, stopping backend...');
      BackendService.instance?.stop();
    }
  }
}
