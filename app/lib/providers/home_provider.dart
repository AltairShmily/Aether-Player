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
  final bool isLoading;
  final String? error;

  HomeState({
    this.resumeItems = const [],
    this.libraries = const [],
    this.libraryItems = const {},
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<MediaItem>? resumeItems,
    List<MediaFolder>? libraries,
    Map<String, List<MediaItem>>? libraryItems,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      resumeItems: resumeItems ?? this.resumeItems,
      libraries: libraries ?? this.libraries,
      libraryItems: libraryItems ?? this.libraryItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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

    state = state.copyWith(isLoading: true, error: null);

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
      );

      // Load items for each library (limited to 15)
      for (final lib in views) {
        if (lib.itemType.isNotEmpty) {
          _loadLibraryItems(serverUrl, auth.token, auth.user.id, lib);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadLibraryItems(
    String serverUrl,
    String token,
    String userId,
    MediaFolder library,
  ) async {
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

      final updated = Map<String, List<MediaItem>>.from(state.libraryItems);
      updated[library.id] = result.items;
      state = state.copyWith(libraryItems: updated);
    } catch (_) {
      // silently ignore per-library errors
    }
  }
}
