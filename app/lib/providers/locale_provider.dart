import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

class LocaleNotifier extends StateNotifier<AppLocale> {
  final StorageService _storage;

  LocaleNotifier(this._storage) : super(AppLocale.zhCn);

  Future<void> load() async {
    final saved = await _storage.getLocale();
    if (saved != null) {
      final locale = AppLocale.values.where((l) => l.languageTag == saved).firstOrNull;
      if (locale != null) {
        state = locale;
        LocaleSettings.setLocale(locale);
      }
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    LocaleSettings.setLocale(locale);
    await _storage.saveLocale(locale.languageTag);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier(ref.read(storageServiceProvider));
});
