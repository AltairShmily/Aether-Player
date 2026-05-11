import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../models/saved_server.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../services/secure_storage_service.dart';
import 'saved_servers_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class AuthState {
  final bool isLoading;
  final String? error;
  final ServerInfo? serverInfo;
  final AuthResult? authResult;

  AuthState({
    this.isLoading = false,
    this.error,
    this.serverInfo,
    this.authResult,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    ServerInfo? serverInfo,
    AuthResult? authResult,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      serverInfo: serverInfo ?? this.serverInfo,
      authResult: authResult ?? this.authResult,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final StorageService _storageService;
  final SecureStorageService _secureStorage;
  final SavedServersNotifier _savedServers;

  AuthNotifier(
    this._apiClient,
    this._storageService,
    this._secureStorage,
    this._savedServers,
  ) : super(AuthState());

  Future<bool> connectToServer(String serverUrl) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final serverInfo = await _apiClient.testConnection(serverUrl);
      state = state.copyWith(isLoading: false, serverInfo: serverInfo);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login(String serverUrl, String username, String password, {bool remember = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _apiClient.login(serverUrl, username, password);

      await _secureStorage.saveToken(result.token);
      await _storageService.saveAuthData(
        token: result.token,
        serverUrl: serverUrl,
        userId: result.user.id,
        userName: result.user.name,
      );

      if (remember) {
        final existing = _savedServers.state.where(
          (s) => s.serverUrl == serverUrl && s.username == username,
        );
        if (existing.isEmpty) {
          final server = SavedServer(
            id: '${serverUrl}_$username',
            serverUrl: serverUrl,
            username: username,
            serverName: result.server.serverName,
            userId: result.user.id,
            lastLoginAt: DateTime.now(),
          );
          await _savedServers.addServer(server, password);
        } else {
          await _savedServers.updateLastLogin(existing.first.id);
        }
      }

      state = state.copyWith(isLoading: false, authResult: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> loginFromSaved(SavedServer server) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final password = await _savedServers.getPassword(server.id);
      if (password == null) {
        state = state.copyWith(isLoading: false, error: 'Password not found');
        return false;
      }
      return await login(server.serverUrl, server.username, password, remember: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    final token = await _secureStorage.getToken();
    final serverUrl = await _storageService.getServerUrl();

    if (token != null && serverUrl != null) {
      final userId = await _storageService.getUserId() ?? '';
      final userName = await _storageService.getUserName() ?? '';

      state = state.copyWith(
        authResult: AuthResult(
          token: token,
          user: UserInfo(id: userId, name: userName),
          server: ServerInfo(serverName: 'Saved Server', version: '', id: ''),
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _secureStorage.deleteToken();
    await _storageService.clearAuthData();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiClientProvider),
    ref.read(storageServiceProvider),
    ref.read(secureStorageServiceProvider),
    ref.read(savedServersProvider.notifier),
  );
});
