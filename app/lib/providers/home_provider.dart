import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_models.dart';
import '../services/api_client.dart';
import '../providers/auth_provider.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref);
});

class HomeState {
  final List<MediaItem> resumeItems;
  final List<MediaFolder> libraries;
  final Map<String, List<MediaItem>> libraryItems;

  /// 各媒体库的条目总数（libraryId → TotalRecordCount）。
  ///
  /// 零额外请求即可获得：加载各库条目时 getItems 的响应本身就带
  /// totalRecordCount，此前被直接丢弃。库卡副文案据此显示「N 部」，
  /// 取代原先写死且不提供任何信息的「点击查看」。
  final Map<String, int> libraryCounts;

  final bool isLoading;
  final String? error;

  HomeState({
    this.resumeItems = const [],
    this.libraries = const [],
    this.libraryItems = const {},
    this.libraryCounts = const {},
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<MediaItem>? resumeItems,
    List<MediaFolder>? libraries,
    Map<String, List<MediaItem>>? libraryItems,
    Map<String, int>? libraryCounts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      resumeItems: resumeItems ?? this.resumeItems,
      libraries: libraries ?? this.libraries,
      libraryItems: libraryItems ?? this.libraryItems,
      libraryCounts: libraryCounts ?? this.libraryCounts,
      isLoading: isLoading ?? this.isLoading,
      // 默认保留已有错误：否则任何无关字段更新都会把错误信息抹掉
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;
  static const int _libraryLimit = 15;

  HomeNotifier(this._ref) : super(HomeState());

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> loadAll() async {
    final auth = _ref.read(authProvider).authResult;
    if (auth == null) return;

    final serverUrl = await _ref.read(storageServiceProvider).getServerUrl();
    if (serverUrl == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load resume items and libraries in parallel
      final results = await Future.wait([
        _api.getResumeItems(
          serverUrl: serverUrl,
          token: auth.token,
          userId: auth.user.id,
          limit: _libraryLimit,
        ),
        _api.getUserViews(
          serverUrl: serverUrl,
          token: auth.token,
          userId: auth.user.id,
        ),
      ]);

      final resumeResult = results[0] as ItemListResponse;
      final views = results[1] as List<MediaFolder>;

      state = state.copyWith(
        resumeItems: resumeResult.items,
        libraries: views,
        isLoading: false,
        clearError: true,
      );

      // 逐个媒体库加载条目（每库上限 15 条）。
      // 不 await：让首屏的英雄区与续播列表先渲染，各行随后填充。
      final targets =
          views.where((lib) => lib.itemType.isNotEmpty).toList();
      if (targets.isNotEmpty) {
        _loadLibraryItems(serverUrl, auth.token, auth.user.id, targets);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 并发拉取多个媒体库的条目，但只写入一次 state。
  ///
  /// 若每个库各自 copyWith，后完成者会以旧的 libraryItems 为基底，
  /// 覆盖掉先完成者刚写入的结果，表现为首页媒体行随机消失。
  Future<void> _loadLibraryItems(
    String serverUrl,
    String token,
    String userId,
    List<MediaFolder> libraries,
  ) async {
    final results = await Future.wait(
      libraries.map((library) async {
        try {
          final result = await _api.getItems(
            serverUrl: serverUrl,
            token: token,
            userId: userId,
            limit: _libraryLimit,
            sortBy: 'DateCreated',
            sortOrder: 'Descending',
            parentId: library.id,
            includeItemTypes: library.itemType,
            recursive: true,
          );
          return (
            id: library.id,
            items: result.items,
            // 响应自带总数，无需为库卡的「N 部」文案额外发请求
            count: result.totalRecordCount,
          );
        } catch (e) {
          // 单个媒体库失败不应拖垮整屏，但也不能完全无声
          debugPrint('[home] library ${library.name} failed: $e');
          return null;
        }
      }),
    );

    final updatedItems = Map<String, List<MediaItem>>.from(state.libraryItems);
    final updatedCounts = Map<String, int>.from(state.libraryCounts);
    for (final r in results.nonNulls) {
      updatedItems[r.id] = r.items;
      updatedCounts[r.id] = r.count;
    }
    state = state.copyWith(
      libraryItems: updatedItems,
      libraryCounts: updatedCounts,
    );
  }
}
