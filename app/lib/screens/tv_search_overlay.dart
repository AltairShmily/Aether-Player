import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../models/media_models.dart' show SearchHint;
import '../providers/auth_provider.dart';

/// TV 搜索界面 — 全屏覆盖层
///
/// 支持 D-Pad 导航和外接键盘输入
class TvSearchOverlay extends ConsumerStatefulWidget {
  const TvSearchOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const TvSearchOverlay();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<TvSearchOverlay> createState() => _TvSearchOverlayState();
}

class _TvSearchOverlayState extends ConsumerState<TvSearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  List<SearchHint> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final authResult = ref.read(authProvider).authResult;
    final token = authResult?.token;
    final userId = authResult?.user.id;
    final serverUrl = await ref.read(storageServiceProvider).getServerUrl();
    if (token == null || serverUrl == null || userId == null) return;

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.search(
        serverUrl: serverUrl,
        token: token,
        userId: userId,
        term: query,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _searchResults = response.searchHints;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(56, 60, 56, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 搜索输入框 ──
              _buildSearchInput(),
              const SizedBox(height: 32),
              // ── 搜索结果 ──
              Expanded(
                child: _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      width: 500,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.stardust,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.celestialCyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _inputFocusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
              decoration: const InputDecoration(
                hintText: '搜索电影、剧集、动漫...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 18,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                _onSearchChanged('');
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.celestialCyan,
          strokeWidth: 2,
        ),
      );
    }

    if (_controller.text.isEmpty) {
      return const Center(
        child: Text(
          '输入关键词开始搜索',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          '未找到相关结果',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2 / 3,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _buildResultCard(item);
      },
    );
  }

  Widget _buildResultCard(SearchHint item) {
    final serverUrl = 'http://localhost:19800';
    final imageUrl = item.hasImage
        ? '$serverUrl/api/images/${item.id}/Primary?maxWidth=300'
        : null;

    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: () {
              // SearchHint 只包含基本信息，关闭搜索
              Navigator.of(context).pop();
            },
            child: AnimatedScale(
              scale: isFocused ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusLg),
                  border: isFocused
                      ? Border.all(color: AppColors.celestialCyan, width: 3)
                      : null,
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.celestialCyan.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppColors.radiusLg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 海报
                      if (imageUrl != null)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      else
                        _placeholder(),
                      // 底部渐变
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xCC0A0E14),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 标题
                      Positioned(
                        bottom: 8,
                        left: 10,
                        right: 10,
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.stardust,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.textSecondary,
          size: 32,
        ),
      ),
    );
  }
}
