import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'aether_emby_token';
  static const String _passwordPrefix = 'aether_pwd_';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> savePassword(String serverId, String password) async {
    await _storage.write(key: '$_passwordPrefix$serverId', value: password);
  }

  Future<String?> getPassword(String serverId) async {
    return _storage.read(key: '$_passwordPrefix$serverId');
  }

  Future<void> deletePassword(String serverId) async {
    await _storage.delete(key: '$_passwordPrefix$serverId');
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
