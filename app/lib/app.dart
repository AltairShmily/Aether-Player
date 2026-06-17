import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'i18n/strings.g.dart';
import 'screens/server_selection_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

class AetherApp extends ConsumerWidget {
  /// Go 后端是否已就绪
  final bool backendReady;

  const AetherApp({super.key, this.backendReady = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Aether',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme(dynamicScheme: darkDynamic),
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: backendReady
              ? const ServerSelectionScreen()
              : const _BackendErrorScreen(),
        );
      },
    );
  }
}

/// 后端启动失败时的错误页面
class _BackendErrorScreen extends StatelessWidget {
  const _BackendErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '后端服务启动失败',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '无法连接到本地代理服务。\n请检查 aether-server 是否在程序同目录下。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  // 重新启动应用
                  // SystemNavigator.pop() 退出后由系统重启
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.celestialCyan,
                  foregroundColor: AppColors.deepVoid,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
