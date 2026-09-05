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
    bool clearError = false,
    ServerInfo? serverInfo,
    AuthResult? authResult,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      // 默认保留已有错误：否则任何无关字段更新都会把错误信息抹掉
      error: clearError ? null : (error ?? this.error),
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final serverInfo = await _apiClient.testConnection(serverUrl);
      state = state.copyWith(
        isLoading: false,
        serverInfo: serverInfo,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login(String serverUrl, String username, String password, {bool remember = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _apiClient.login(serverUrl, username, password);

      await _secureStorage.saveToken(result.token);
      await _storageService.saveAuthData(
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

      state = state.copyWith(
        isLoading: false,
        authResult: result,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> loginFromSaved(SavedServer server) async {
    state = state.copyWith(isLoading: true, clearError: true);
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

  /// 使用已保存的凭据恢复会话。
  ///
  /// 恢复前必须校验令牌有效性：直接信任本地令牌会在其过期后把用户送进
  /// 一个所有请求都失败、且异常被下游静默吞掉的空白首页。
  /// 校验失败时**不清除**凭据 —— 失败也可能只是网络或服务器临时不可达，
  /// 抹掉令牌会迫使用户重新输入密码。
  Future<bool> tryAutoLogin() async {
    final token = await _secureStorage.getToken();
    final serverUrl = await _storageService.getServerUrl();

    if (token == null || serverUrl == null) return false;

    final userId = await _storageService.getUserId() ?? '';
    final userName = await _storageService.getUserName() ?? '';

    try {
      final profile = await _apiClient.getUserProfile(
        serverUrl: serverUrl,
        token: token,
        userId: userId,
      );

      state = state.copyWith(
        authResult: AuthResult(
          token: token,
          user: UserInfo(
            id: userId,
            name: profile['Name'] as String? ?? userName,
          ),
          server: ServerInfo(serverName: 'Saved Server', version: '', id: ''),
        ),
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        error: '登录状态已失效或服务器无法连接，请重新登录',
      );
      return false;
    }
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
