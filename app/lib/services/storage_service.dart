import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_server.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _serverUrlKey = 'server_url';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _savedServersKey = 'saved_servers';
  static const String _localeKey = 'locale';

  Future<void> saveAuthData({
    required String token,
    required String serverUrl,
    required String userId,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_serverUrlKey, serverUrl);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
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
