import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

class LocaleNotifier extends StateNotifier<AppLocale> {
  final StorageService _storage;

  /// [initial] 由 main() 在启动时从持久化存储读取后注入，
  /// 需与 LocaleSettings 的全局当前语言保持一致。
  LocaleNotifier(this._storage, {AppLocale? initial})
      : super(initial ?? AppLocale.zhCn);

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    LocaleSettings.setLocale(locale);
    await _storage.saveLocale(locale.languageTag);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier(ref.read(storageServiceProvider));
});
