import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_server.dart';
import '../services/storage_service.dart';
import '../services/secure_storage_service.dart';
import 'auth_provider.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

class SavedServersNotifier extends StateNotifier<List<SavedServer>> {
  final StorageService _storage;
  final SecureStorageService _secureStorage;

  SavedServersNotifier(this._storage, this._secureStorage) : super(const []);

  Future<void> load() async {
    state = await _storage.getSavedServers();
  }

  Future<void> addServer(SavedServer server, String password) async {
    await _secureStorage.savePassword(server.id, password);
    state = [...state, server];
    await _storage.saveServers(state);
  }

  Future<void> removeServer(String serverId) async {
    await _secureStorage.deletePassword(serverId);
    state = state.where((s) => s.id != serverId).toList();
    await _storage.saveServers(state);
  }

  Future<String?> getPassword(String serverId) async {
    return _secureStorage.getPassword(serverId);
  }

  Future<void> updateLastLogin(String serverId) async {
    state = state.map((s) {
      if (s.id == serverId) {
        return s.copyWith(lastLoginAt: DateTime.now());
      }
      return s;
    }).toList();
    await _storage.saveServers(state);
  }
}

final savedServersProvider =
    StateNotifierProvider<SavedServersNotifier, List<SavedServer>>((ref) {
  return SavedServersNotifier(
    ref.read(storageServiceProvider),
    ref.read(secureStorageServiceProvider),
  );
});
