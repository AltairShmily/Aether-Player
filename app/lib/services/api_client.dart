import 'package:dio/dio.dart';
import '../models/auth_models.dart';

class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio() {
    _dio.options.baseUrl = 'http://localhost:8080';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<ServerInfo> testConnection(String serverUrl) async {
    try {
      final response = await _dio.post(
        '/api/auth/connect',
        data: {'server_url': serverUrl},
      );
      return ServerInfo.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to connect: ${e.message}');
    }
  }

  Future<AuthResult> login(String serverUrl, String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'server_url': serverUrl,
          'username': username,
          'password': password,
        },
      );
      return AuthResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Login failed: ${e.message}');
    }
  }
}
