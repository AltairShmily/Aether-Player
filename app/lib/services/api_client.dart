import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import '../models/media_models.dart';
class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio() {
    _dio.options.baseUrl = 'http://localhost:19800';
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

  // --- Library ---

  Future<List<MediaFolder>> getUserViews({
    required String serverUrl,
    required String token,
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/library/views',
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
            'X-Emby-User': userId,
          },
        ),
      );
      final items = (response.data['Items'] as List<dynamic>?)
              ?.map((e) => MediaFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return items;
    } on DioException catch (e) {
      throw Exception('Failed to get user views: ${e.message}');
    }
  }

  Future<ItemListResponse> getResumeItems({
    required String serverUrl,
    required String token,
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/library/resume',
        queryParameters: {'limit': limit},
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
            'X-Emby-User': userId,
          },
        ),
      );
      return ItemListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get resume items: ${e.message}');
    }
  }

  Future<ItemListResponse> getSeasons({
    required String serverUrl,
    required String token,
    required String seriesId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/library/seasons',
        queryParameters: {'seriesId': seriesId},
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
          },
        ),
      );
      return ItemListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get seasons: ${e.message}');
    }
  }

  Future<ItemListResponse> getEpisodes({
    required String serverUrl,
    required String token,
    required String seriesId,
    required String seasonId,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/library/episodes',
        queryParameters: {
          'seriesId': seriesId,
          'seasonId': seasonId,
          'limit': limit,
        },
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
          },
        ),
      );
      return ItemListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get episodes: ${e.message}');
    }
  }

  Future<ItemListResponse> getItems({
    required String serverUrl,
    required String token,
    required String userId,
    int startIndex = 0,
    int limit = 20,
    String sortBy = 'DateCreated',
    String sortOrder = 'Descending',
    String? includeItemTypes,
    bool recursive = true,
    String? searchTerm,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startIndex': startIndex,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'recursive': recursive,
      };
      if (includeItemTypes != null) queryParams['includeItemTypes'] = includeItemTypes;
      if (searchTerm != null && searchTerm.isNotEmpty) queryParams['searchTerm'] = searchTerm;

      final response = await _dio.get(
        '/api/library/items',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
            'X-Emby-User': userId,
          },
        ),
      );
      return ItemListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get items: ${e.message}');
    }
  }

  Future<MediaItem> getItemDetail({
    required String serverUrl,
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/library/items/$itemId',
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
          },
        ),
      );
      return MediaItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get item detail: ${e.message}');
    }
  }

  String getImageUrl({
    required String serverUrl,
    required String token,
    required String itemId,
    String imageType = 'Primary',
    int? maxWidth,
  }) {
    var url = 'http://localhost:8080/api/images/$itemId/$imageType';
    if (maxWidth != null) url += '?maxWidth=$maxWidth';
    return url;
  }

  Future<SearchResult> search({
    required String serverUrl,
    required String token,
    required String userId,
    required String term,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/search',
        queryParameters: {'term': term, 'limit': limit},
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
            'X-Emby-User': userId,
          },
        ),
      );
      return SearchResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Search failed: ${e.message}');
    }
  }

  Future<MediaStreamInfo> getPlaybackInfo({
    required String serverUrl,
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/playback/$itemId/info',
        options: Options(
          headers: {
            'X-Emby-Server': serverUrl,
            'X-Emby-Token': token,
          },
        ),
      );
      return MediaStreamInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get playback info: ${e.message}');
    }
  }
}
