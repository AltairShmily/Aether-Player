import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_server.dart';

class StorageService {
  /// 仅用于清理旧版本遗留的明文令牌 —— 令牌本身一律存放于安全存储
  static const String _tokenKey = 'auth_token';
  static const String _serverUrlKey = 'server_url';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _savedServersKey = 'saved_servers';
  static const String _localeKey = 'locale';

  /// 保存非敏感的认证上下文（服务器地址与用户标识）。
  /// 访问令牌不在此列，须通过 [SecureStorageService] 存取。
  Future<void> saveAuthData({
    required String serverUrl,
    required String userId,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, serverUrl);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    // 清理旧版本遗留的明文令牌，避免升级后长期残留
    await prefs.remove(_tokenKey);
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_serverUrlKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
  }

  // Saved servers
  Future<List<SavedServer>> getSavedServers() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_savedServersKey);
    if (json == null) return [];
    return SavedServer.listFromJson(json);
  }

  Future<void> saveServers(List<SavedServer> servers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedServersKey, SavedServer.listToJson(servers));
  }

  // Locale
  Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }
}
