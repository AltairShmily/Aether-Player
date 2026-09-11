import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../services/api_client.dart';
import '../models/media_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_breakpoints.dart';
import '../utils/media_navigation.dart';
import '../widgets/aether_card.dart';
import '../widgets/aether_button.dart';
import '../widgets/aether_hero.dart';
import '../widgets/media_card.dart';
import '../widgets/scroll_arrows.dart';
import '../widgets/aether_page_route.dart';
import 'server_selection_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String? _serverUrl;
  final PageController _heroController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  String? _selectedCategory; // null = 全部, 'movies', 'tvshows', 'music'

  void _showSearchOverlay(BuildContext context) {
    showSearchDialog(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServerUrl();
      ref.read(homeProvider.notifier).loadAll();
    });
  }

  Future<void> _loadServerUrl() async {
    final url = await ref.read(storageServiceProvider).getServerUrl();
    if (mounted) setState(() => _serverUrl = url);
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final userName = authState.authResult?.user.name ?? '';
    final token = authState.authResult?.token;
    final pad = AetherBreakpoints.pagePadding(context);

    return Stack(
      children: [
        // ── 双层径向渐变光晕背景 ──
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.6, -0.4),
                radius: 0.8,
                colors: [
                  AppColors.celestialCyan.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, 0.3),
                radius: 0.9,
                colors: [
                  AppColors.novaPurple.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // ── 主内容 ──
        CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.deepVoid,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.deepVoid,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AETHER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  onPressed: () => _showSearchOverlay(context),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: () => ref.read(homeProvider.notifier).loadAll(),
                ),
              ],
            ),

            // ── Welcome ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 8, pad, 20),
                child: Text(
                  t.home.welcome(name: userName),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            // ── Loading ──
            if (homeState.isLoading && homeState.resumeItems.isEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.celestialCyan,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),

            // ── Hero Banner (Resume 首项) ──
            if (homeState.resumeItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: AetherBreakpoints.heroHeight(context),
                      child: PageView.builder(
                        controller: _heroController,
                        itemCount: homeState.resumeItems.length.clamp(0, 5),
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          final item = homeState.resumeItems[index];
                          final imageUrl = ApiClient.imageProxyUrl(
                            item.id,
                            type: 'Backdrop',
                            maxWidth: 800,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AetherHero.carousel(
                              imageUrl: imageUrl,
                              title: item.isEpisode ? item.seriesName : item.name,
                              subtitle: item.isEpisode
                                  ? '${item.episodeLabel} · ${item.overview}'
                                  : item.overview,
                              tags: [
                                if (item.isEpisode) '剧集',
                                if (item.isMovie) '电影',
                                if (item.productionYear > 0) '${item.productionYear}',
                              ],
                              rating: item.communityRating,
                              primaryAction: AetherButton.primary(
                                label: '继续播放',
                                icon: Icons.play_arrow_rounded,
                                compact: true,
                                onPressed: () => openMediaItem(context, item),
                              ),
                              onTap: () => openMediaItem(context, item),
                            ),
                          );
                        },
                      ),
                    ),
                    // ── Carousel dot indicators ──
                    if (homeState.resumeItems.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            homeState.resumeItems.length.clamp(0, 5),
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentPage == index ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? AppColors.celestialCyan
                                    : AppColors.textTertiary.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // ── Error ──
            if (homeState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            homeState.error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Continue Watching ──
            if (homeState.resumeItems.isNotEmpty)
              SliverToBoxAdapter(
                child: _SectionRow(
                  title: t.home.continueWatching,
                  items: homeState.resumeItems,
                  serverUrl: _serverUrl,
                  token: token,
                  titleIcon: Icons.play_circle_outline,
                ),
              ),

            // ── Library Shortcuts ──
            if (homeState.libraries.isNotEmpty)
              SliverToBoxAdapter(
                child: _LibraryRow(
                  libraries: homeState.libraries,
                  serverUrl: _serverUrl,
                  token: token,
                ),
              ),
            // ── 分类筛选标签 ──
            if (homeState.libraries.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoryFilterBar(
                  libraries: homeState.libraries,
                  onFilterChanged: (type) {
                    setState(() => _selectedCategory = type);
                  },
                ),
              ),

            // ── Per-library rows ──
            for (final lib in homeState.libraries.where((lib) {
              if (_selectedCategory == null) return true;
              return lib.collectionType == _selectedCategory;
            })) ...[
              if (homeState.libraryItems.containsKey(lib.id) &&
                  homeState.libraryItems[lib.id]!.isNotEmpty)
                SliverToBoxAdapter(
                  child: _SectionRow(
                    title: lib.name,
                    items: homeState.libraryItems[lib.id]!,
                    serverUrl: _serverUrl,
                    token: token,
                    titleIcon: _iconForType(lib.collectionType),
                  ),
                ),
            ],

            // ── Account Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 40, pad, 32),
                child: AetherCard.simple(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.deepVoid,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authState.authResult?.server.serverName ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AetherButton.ghost(
                        label: '切换',
                        icon: Icons.swap_horiz_rounded,
                        compact: true,
                        onPressed: () => _switchAccount(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _switchAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('切换账号'),
        content: const Text('确定要退出当前账号并返回服务器选择页面吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translations.of(context).common.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  AetherPageRoute(page: const ServerSelectionScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'movies':
        return Icons.movie_creation;
      case 'tvshows':
        return Icons.tv;
      case 'music':
        return Icons.music_note;
      default:
        return Icons.video_library;
    }
  }
  }

// ══════════════════════════════════════════════════
//  _SectionRow — 杂志感分类行
// ══════════════════════════════════════════════════
class _SectionRow extends StatefulWidget {
  final String title;
  final List<MediaItem> items;
  final String? serverUrl;
  final String? token;
  final IconData? titleIcon;

  const _SectionRow({
    required this.title,
    required this.items,
    this.serverUrl,
    this.token,
    this.titleIcon,
  });

  @override
  State<_SectionRow> createState() => _SectionRowState();
}

class _SectionRowState extends State<_SectionRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = AetherBreakpoints.pagePadding(context);
    final cardH = AetherBreakpoints.isMobile(context) ? 180.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 28, pad, 14),
          child: Row(
            children: [
              Icon(
                widget.titleIcon ?? Icons.local_movies,
                size: 20,
                color: AppColors.celestialCyan,
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // TODO: 导航到库详情页
                  },
                  child: const _SeeAllButton(),
                ),
              ),
            ],
          ),
        ),
        // 卡片行
        SizedBox(
          height: cardH,
          child: ScrollArrows(
            scrollController: _scrollController,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: pad),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: AetherBreakpoints.cardSpacing(context)),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final progress = item.userData?.progressPercent ?? 0;
                // 横向行内宽度不受限、高度由外层 SizedBox 固定，
                // 故自己给定宽度，海报填满标题行之外的剩余空间
                return SizedBox(
                  width: 152,
                  child: MediaCard(
                    item: item,
                    onTap: () => openMediaItem(context, item),
                    imageHeaders: {
                      'X-Emby-Server': widget.serverUrl ?? '',
                      'X-Emby-Token': widget.token ?? '',
                    },
                    progress: progress > 0 ? progress : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
//  _LibraryRow — 媒体库快捷入口
// ══════════════════════════════════════════════════
class _LibraryRow extends StatefulWidget {
  final List<MediaFolder> libraries;
  final String? serverUrl;
  final String? token;

  const _LibraryRow({
    required this.libraries,
    this.serverUrl,
    this.token,
  });

  @override
  State<_LibraryRow> createState() => _LibraryRowState();
}

class _LibraryRowState extends State<_LibraryRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = AetherBreakpoints.pagePadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 28, pad, 14),
          child: Row(
            children: [
              const Icon(
                Icons.video_library,
                size: 20,
                color: AppColors.celestialCyan,
              ),
              const SizedBox(width: 10),
              const Text(
                '媒体库',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ScrollArrows(
            scrollController: _scrollController,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: pad),
              itemCount: widget.libraries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final lib = widget.libraries[index];
              return AetherCard.simple(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.celestialCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForType(lib.collectionType),
                        color: AppColors.celestialCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lib.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _typeLabel(lib.collectionType),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            ),
          ),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'movies':
        return '电影';
      case 'tvshows':
        return '电视剧';
      case 'music':
        return '音乐';
      default:
        return '混合';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'movies':
        return Icons.movie_outlined;
      case 'tvshows':
        return Icons.tv_outlined;
      case 'music':
        return Icons.music_note_outlined;
      default:
        return Icons.video_library_outlined;
    }
  }
}


// ══════════════════════════════════════════════════
//  _SearchDialog — 搜索对话框
// ══════════════════════════════════════════════════

/// 弹出搜索对话框。
///
/// 抽为顶层函数，让 ShellScreen 的 Ctrl+K 搜索叠加层提交后也能复用
/// 同一套搜索实现，避免两处各写一份。
Future<void> showSearchDialog(
  BuildContext context, {
  String initialQuery = '',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SearchDialog(initialQuery: initialQuery),
  );
}

class _SearchDialog extends ConsumerStatefulWidget {
  final String initialQuery;

  const _SearchDialog({this.initialQuery = ''});

  @override
  ConsumerState<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<_SearchDialog> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  String _query = '';
  List<SearchHint> _results = const [];
  bool _searching = false;
  String? _error;

  /// 结果缩略图经本地代理获取时需要转发的上游地址与令牌
  String? _serverUrl;
  String? _token;

  /// 输入防抖，避免每敲一个字符就发一次请求
  Timer? _debounce;
  static const _debounceDelay = Duration(milliseconds: 350);

  /// 请求序号：只采纳最后一次请求的结果，防止慢响应覆盖新查询
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      // 由快捷键叠加层带入关键词时立即搜一次
      final term = widget.initialQuery.trim();
      if (term.isNotEmpty) _performSearch(term);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();

    final term = value.trim();
    if (term.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(_debounceDelay, () => _performSearch(term));
  }

  Future<void> _performSearch(String term) async {
    final seq = ++_requestSeq;
    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final auth = ref.read(authProvider).authResult;
      final serverUrl = await ref.read(storageServiceProvider).getServerUrl();
      if (auth == null || serverUrl == null) {
        throw Exception('missing auth context');
      }

      // 结果缩略图经本地代理获取，需要这两个值构造转发头
      _serverUrl = serverUrl;
      _token = auth.token;

      final result = await ref.read(apiClientProvider).search(
            serverUrl: serverUrl,
            token: auth.token,
            userId: auth.user.id,
            term: term,
          );

      // 期间已发出更新的请求，丢弃这次过时的结果
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _results = result.searchHints;
        _searching = false;
      });
    } catch (e) {
      debugPrint('[search] failed: $e');
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _searching = false;
        _results = const [];
        // 面向用户的可读文案，技术细节只进日志
        _error = '搜索失败，请检查网络后重试';
      });
    }
  }

  void _openResult(SearchHint hint) {
    final item = MediaItem(
      id: hint.id,
      name: hint.name,
      type: hint.type,
      overview: hint.overview,
      communityRating: hint.communityRating,
      productionYear: hint.productionYear,
      primaryImageTag: hint.primaryImageTag,
    );

    // 先捕获 Navigator：pop 之后 context 即失效，不能再用于 push
    final navigator = Navigator.of(context);
    navigator.pop();

    final Widget dest = detailPageFor(item);
    navigator.push(
      AetherPageRoute(page: dest, type: AetherTransitionType.slideFromRight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.nebulaDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 搜索框 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '搜索电影、剧集、音乐…',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.stardust,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.celestialCyan, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  final term = v.trim();
                  if (term.isNotEmpty) _performSearch(term);
                },
              ),
            ),
            // ── 结果区域 ──
            Expanded(child: _buildResultArea()),
          ],
        ),
      ),
    );
  }

  /// 加载中 / 失败 / 无结果 / 有结果 四态
  Widget _buildResultArea() {
    if (_searching) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.celestialCyan,
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildMessage(Icons.error_outline, _error!);
    }

    if (_query.trim().isEmpty) {
      return _buildMessage(Icons.search_rounded, '输入关键词搜索');
    }

    if (_results.isEmpty) {
      return _buildMessage(Icons.search_off_rounded, '没有找到「$_query」相关内容');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final hint = _results[index];
        // 复用共享组件而非在本文件内联一份，避免与其它页面的搜索结果卡漂移
        return SearchHintCard(
          hint: hint,
          onTap: () => _openResult(hint),
          imageHeaders: {
            'X-Emby-Server': _serverUrl ?? '',
            'X-Emby-Token': _token ?? '',
          },
        );
      },
    );
  }

  Widget _buildMessage(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  _CategoryFilterBar — 分类筛选标签栏
// ══════════════════════════════════════════════════
class _CategoryFilterBar extends StatefulWidget {
  final List<MediaFolder> libraries;
  final ValueChanged<String?> onFilterChanged;

  const _CategoryFilterBar({
    required this.libraries,
    required this.onFilterChanged,
  });

  @override
  State<_CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<_CategoryFilterBar> {
  String? _selected; // null = 全部

  @override
  Widget build(BuildContext context) {
    final pad = AetherBreakpoints.pagePadding(context);

    // 收集可用的分类类型
    final types = widget.libraries.map((l) => l.collectionType).toSet().toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('全部', null),
            const SizedBox(width: 8),
            for (final type in types) ...[
              _buildChip(_typeLabel(type), type),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String? type) {
    final isSelected = _selected == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selected = type);
        widget.onFilterChanged(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.celestialCyan.withValues(alpha: 0.15)
              : AppColors.stardust,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.celestialCyan.withValues(alpha: 0.4)
                : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.celestialCyan : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'movies': return '🎬 电影';
      case 'tvshows': return '📺 电视剧';
      case 'music': return '🎵 音乐';
      default: return '📁 $type';
    }
  }
}

// ══════════════════════════════════════════════════
//  _SeeAllButton — 查看全部按钮（hover 效果）
// ══════════════════════════════════════════════════
class _SeeAllButton extends StatefulWidget {
  const _SeeAllButton();

  @override
  State<_SeeAllButton> createState() => _SeeAllButtonState();
}

class _SeeAllButtonState extends State<_SeeAllButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.celestialCyan.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
        ),
        child: Text(
          '查看全部 →',
          style: TextStyle(
            fontSize: 10.9,
            color: _isHovered ? AppColors.celestialCyan : AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
