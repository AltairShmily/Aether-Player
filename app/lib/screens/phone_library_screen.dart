import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_breakpoints.dart';
import '../models/media_models.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../widgets/aether_page_route.dart';
import '../widgets/media_card.dart';
import '../widgets/skeleton_loader.dart';
import 'series_detail_screen.dart';
import 'episode_detail_screen.dart';
import 'media_detail_screen.dart';

/// Phone 媒体库页面 — 匹配设计稿
///
/// 显示所有媒体库的网格视图，点击进入具体库
class PhoneLibraryScreen extends ConsumerStatefulWidget {
  const PhoneLibraryScreen({super.key});

  @override
  ConsumerState<PhoneLibraryScreen> createState() => _PhoneLibraryScreenState();
}

class _PhoneLibraryScreenState extends ConsumerState<PhoneLibraryScreen> {
  String? _serverUrl;
  String? _token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final url = await ref.read(storageServiceProvider).getServerUrl();
    final token = ref.read(authProvider).authResult?.token;
    if (mounted) {
      setState(() {
        _serverUrl = url;
        _token = token;
      });
    }
    ref.read(homeProvider.notifier).loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final pad = AetherBreakpoints.pagePadding(context);
    return _buildLibraryGrid(homeState, pad);
  }

  Widget _buildLibraryGrid(HomeState homeState, double pad) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 20),
            child: const Text(
              '媒体库',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          sliver: SliverGrid(
            // 按最大块宽自适应列数：写死列数会在宽屏下把每块撑得过大
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 16 / 10,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final lib = homeState.libraries[index];
              return _buildLibCard(lib, homeState.libraryCounts[lib.id]);
            }, childCount: homeState.libraries.length),
          ),
        ),
      ],
    );
  }

  /// 库卡副文案：条目数量 + 按类型选择的量词。
  ///
  /// 此前写死「点击查看」，不传达任何信息，用户无法判断库里有什么、规模多大。
  /// 数量取自 getItems 响应自带的 TotalRecordCount，无需额外请求。
  /// 尚未加载到时显示「加载中…」，而不是误导性的 0。
  String _libCountLabel(String collectionType, int? count) {
    if (count == null) return '加载中…';
    final unit = switch (collectionType) {
      'movies' || 'tvshows' => '部',
      'music' => '首',
      'photos' => '张',
      'books' => '本',
      _ => '项',
    };
    return '$count $unit';
  }

  /// [itemCount] 为该库的条目总数，null 表示尚未加载到
  Widget _buildLibCard(MediaFolder lib, int? itemCount) {
    // 根据库类型选择图标和颜色
    IconData icon;
    Color color;
    switch (lib.collectionType) {
      case 'movies':
        icon = Icons.movie_outlined;
        color = AppColors.auroraGreen;
        break;
      case 'tvshows':
        icon = Icons.tv_outlined;
        color = AppColors.novaPurple;
        break;
      case 'music':
        icon = Icons.music_note_outlined;
        color = AppColors.plasmaPink;
        break;
      default:
        icon = Icons.video_library_outlined;
        color = AppColors.celestialCyan;
    }

    return _HoverableLibCard(
      onTap: () {
        Navigator.of(context).push(
          AetherPageRoute(
            page: _LibraryContentPage(
              lib: lib,
              serverUrl: _serverUrl,
              token: _token,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nebulaDark, AppColors.stardust],
          ),
        ),
        child: Stack(
          children: [
            // 渐变遮罩
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusLg),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.deepVoid.withValues(alpha: 0.6),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color.withValues(alpha: 0.8), size: 26),
                  const SizedBox(height: 4),
                  Text(
                    lib.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _libCountLabel(lib.collectionType, itemCount),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontFamily: 'DM Mono',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 库内容页的排序方式。label 用于 Chip 文案，sortBy/sortOrder 交给后端。
enum _LibrarySort {
  recentlyAdded('最近添加', 'DateCreated', 'Descending'),
  name('名称', 'SortName', 'Ascending'),
  year('年份', 'PremiereDate', 'Descending'),
  rating('评分', 'CommunityRating', 'Descending');

  const _LibrarySort(this.label, this.sortBy, this.sortOrder);

  final String label;
  final String sortBy;
  final String sortOrder;
}

class _LibraryContentPage extends ConsumerStatefulWidget {
  final MediaFolder lib;

  /// 远端 Emby 地址（用于图片请求头）；为空时回退到存储读取
  final String? serverUrl;
  final String? token;

  const _LibraryContentPage({required this.lib, this.serverUrl, this.token});

  @override
  ConsumerState<_LibraryContentPage> createState() =>
      _LibraryContentPageState();
}

class _LibraryContentPageState extends ConsumerState<_LibraryContentPage> {
  /// 内容页自行拉取数据，而非复用首页那份上限 15 条的快照：
  /// 在 15 条上做筛选与排序会让用户误以为在操作整个媒体库
  static const int _pageLimit = 200;

  List<MediaItem> _items = const [];
  bool _loading = true;
  String? _error;

  /// 后端报告的条目总数。与 _items.length 不等时说明结果被 _pageLimit 截断
  int _totalCount = 0;

  /// 类型筛选，null = 全部
  String? _typeFilter;

  /// 可选类型，取自首次（未筛选）加载结果，避免筛选后选项自我收缩
  List<String> _availableTypes = const [];

  _LibrarySort _sort = _LibrarySort.recentlyAdded;

  String? _embyServerUrl;

  @override
  void initState() {
    super.initState();
    _embyServerUrl = widget.serverUrl;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authProvider).authResult;
      final embyUrl =
          _embyServerUrl ??
          await ref.read(storageServiceProvider).getServerUrl();
      if (auth == null || embyUrl == null) {
        throw Exception('missing auth context');
      }
      _embyServerUrl = embyUrl;

      // itemType 对 photos/books/mixed 等类型返回空串，传空的 includeItemTypes
      // 会让这类库永远查不到内容，故留空即不加类型过滤
      final defaultType = widget.lib.itemType;

      final result = await ref
          .read(apiClientProvider)
          .getItems(
            serverUrl: embyUrl,
            token: auth.token,
            userId: auth.user.id,
            limit: _pageLimit,
            // 排序交给后端，而非本地重排已加载的部分数据
            sortBy: _sort.sortBy,
            sortOrder: _sort.sortOrder,
            parentId: widget.lib.id,
            includeItemTypes:
                _typeFilter ?? (defaultType.isEmpty ? null : defaultType),
            recursive: true,
          );

      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalCount = result.totalRecordCount;
        _loading = false;
        // 仅在未筛选时收集类型，否则筛选一次后选项就只剩当前类型
        if (_typeFilter == null && _availableTypes.isEmpty) {
          _availableTypes = result.items
              .map((i) => i.type)
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();
        }
      });
    } catch (e) {
      debugPrint('[library] load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = const [];
        _error = '无法加载媒体库内容，请检查 aether-server 是否运行';
      });
    }
  }

  void _onSortChanged(_LibrarySort sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _load();
  }

  void _onTypeFilterChanged(String? type) {
    if (type == _typeFilter) return;
    setState(() => _typeFilter = type);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部返回栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.nebulaDark,
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.lib.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!_loading && _error == null && _items.isNotEmpty)
                    Text(
                      _totalCount > _items.length
                          ? '${_items.length}/$_totalCount'
                          : '$_totalCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontFamily: 'DM Mono',
                      ),
                    ),
                ],
              ),
            ),

            // ── 筛选 + 排序 ──
            // 加载中也保留：否则切换排序会先收起再展开，整页跟着跳动
            if (_error == null) _buildFilterBar(),

            // ── 内容四态 ──
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  /// 类型筛选 Chip + 排序 Chip。
  /// 仅当库内确实存在多种类型时才显示筛选，否则该操作无意义。
  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (_availableTypes.length > 1) ...[
            _filterChip('全部', null),
            for (final type in _availableTypes)
              _filterChip(_typeLabel(type), type),
            const SizedBox(width: 12),
            // 分隔
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.borderSubtle,
            ),
            const SizedBox(width: 12),
          ],
          for (final sort in _LibrarySort.values) _sortChip(sort),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? type) {
    final selected = _typeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _chip(
        label: label,
        selected: selected,
        onTap: () => _onTypeFilterChanged(type),
      ),
    );
  }

  Widget _sortChip(_LibrarySort sort) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _chip(
        label: sort.label,
        selected: _sort == sort,
        onTap: () => _onSortChanged(sort),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.stardust,
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          border: Border.all(
            color: selected ? AppColors.celestialCyan : AppColors.borderSubtle,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.celestialCyan : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
    'Movie' => '电影',
    'Series' => '剧集',
    'Episode' => '单集',
    'Audio' => '音乐',
    'MusicAlbum' => '专辑',
    'Person' => '人物',
    _ => type,
  };

  /// 加载中 / 错误 / 空 / 正常 四态
  Widget _buildContent() {
    if (_loading) return _buildSkeletonGrid();

    if (_error != null) {
      return _buildMessage(
        Icons.error_outline,
        _error!,
        actionLabel: '重试',
        onAction: _load,
      );
    }

    if (_items.isEmpty) {
      return _buildMessage(
        Icons.video_library_outlined,
        _typeFilter == null ? '这个媒体库还是空的' : '没有符合筛选条件的内容',
        actionLabel: '刷新',
        onAction: _load,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: _gridDelegate,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final progress = item.userData?.progressPercent ?? 0;
        return MediaCard(
          item: item,
          onTap: () => _openItem(item),
          imageUrlBuilder: (id, {type = 'Primary', maxWidth}) =>
              '${ApiClient.proxyBaseUrl}/api/images/$id/$type'
              '${maxWidth != null ? '?maxWidth=$maxWidth' : ''}',
          imageHeaders: {
            'X-Emby-Server': _embyServerUrl ?? '',
            'X-Emby-Token':
                widget.token ?? ref.read(authProvider).authResult?.token ?? '',
          },
          progress: progress > 0 ? progress : null,
        );
      },
    );
  }

  /// 与骨架网格共用，避免加载完成时布局跳动
  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 150,
    mainAxisSpacing: 12,
    crossAxisSpacing: 10,
    // MediaCard 在海报下方还有标题行与 meta 行（约 44px），
    // 沿用 2/3 会把海报挤压得偏离 2:3
    childAspectRatio: 0.55,
  );

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _gridDelegate,
      itemCount: 12,
      itemBuilder: (_, __) => const AetherSkeleton.card(),
    );
  }

  Widget _buildMessage(
    IconData icon,
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.celestialCyan,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openItem(MediaItem item) {
    final Widget dest;
    if (item.isSeries) {
      dest = SeriesDetailScreen(series: item);
    } else if (item.isEpisode) {
      dest = EpisodeDetailScreen(item: item);
    } else {
      dest = MediaDetailScreen(item: item);
    }
    Navigator.of(context).push(
      AetherPageRoute(page: dest, type: AetherTransitionType.slideFromRight),
    );
  }
}

/// 可悬浮的库卡片 — 添加 MouseRegion hover 动画 (translateY -4, scale 1.02)
class _HoverableLibCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableLibCard({required this.onTap, required this.child});

  @override
  State<_HoverableLibCard> createState() => _HoverableLibCardState();
}

class _HoverableLibCardState extends State<_HoverableLibCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _translateAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _translateAnim = Tween<double>(
      begin: 0.0,
      end: -4.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _translateAnim.value),
              child: Transform.scale(scale: _scaleAnim.value, child: child),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
