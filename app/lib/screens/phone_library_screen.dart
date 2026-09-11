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
  final String? selectedLibId;

  const PhoneLibraryScreen({super.key, this.selectedLibId});

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

  @override
  void didUpdateWidget(covariant PhoneLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLibId != widget.selectedLibId &&
        widget.selectedLibId != null) {
      ref.read(homeProvider.notifier).loadAll();
    }
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

    // 如果有外部传入的库 ID，显示该库的内容
    final selectedId = widget.selectedLibId;
    if (selectedId != null) {
      return _buildLibraryContent(homeState, selectedId, pad);
    }

    // 否则显示所有媒体库的网格
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
        if (widget.selectedLibId == null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _LibraryContentPage(
                lib: lib,
                items: ref.read(homeProvider).libraryItems[lib.id] ?? [],
                serverUrl: _serverUrl,
                token: _token,
              ),
            ),
          );
        }
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

  Widget _buildLibraryContent(
    HomeState homeState,
    String selectedId,
    double pad,
  ) {
    final items = homeState.libraryItems[selectedId] ?? [];
    final lib = homeState.libraries.firstWhere(
      (l) => l.id == selectedId,
      orElse: () => MediaFolder(id: '', name: '', collectionType: ''),
    );

    // MediaCard 的调用契约要求图片请求头首帧就绪：_serverUrl 是异步读取的，
    // 未就绪时渲染会让请求带空的 X-Emby-Server 而被代理拒绝(502)，
    // 且 NetworkImage 不会因 headers 变化重新解析，图片将永久停在失败态
    if (_serverUrl == null) {
      return _buildPosterSkeletonGrid(pad);
    }

    return CustomScrollView(
      slivers: [
        // 顶部返回栏
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
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
                Text(
                  lib.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 内容网格
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
          sliver: SliverGrid(
            // 海报按最大块宽自适应列数，避免宽屏下每张海报过大
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              // MediaCard = 海报 + 标题行 + meta 行，比只有海报的内联卡
              // 多出约 44px 文字区。按「海报保持 2:3」反推：
              // 块宽 w 时总高 = 1.5w + 44，比例 = w/(1.5w+44)，
              // 在 100–150px 块宽区间约 0.52–0.56，取 0.55 折中
              childAspectRatio: 0.55,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              return _buildMediaCard(item);
            }, childCount: items.length),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    final progress = item.userData?.progressPercent ?? 0;
    return MediaCard(
      item: item,
      onTap: () => _openItem(item),
      // /api/images 是本地 Go 代理的路由，须走 proxyBaseUrl；
      // 远端 Emby 地址通过 X-Emby-Server 头交给代理转发
      imageUrlBuilder: (id, {type = 'Primary', maxWidth}) =>
          '${ApiClient.proxyBaseUrl}/api/images/$id/$type'
          '${maxWidth != null ? '?maxWidth=$maxWidth' : ''}',
      imageHeaders: {
        'X-Emby-Server': _serverUrl ?? '',
        'X-Emby-Token': _token ?? '',
      },
      progress: progress > 0 ? progress : null,
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

  /// 海报网格骨架，复用共享的 [AetherSkeleton]。
  /// delegate 与真实网格保持一致，避免就绪切换时布局跳动。
  Widget _buildPosterSkeletonGrid(double pad) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(pad, 60, pad, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.55,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => const AetherSkeleton.card(),
    );
  }
}

/// 库内容页面 — 独立页面显示某个库的所有媒体
class _LibraryContentPage extends StatelessWidget {
  final MediaFolder lib;
  final List<MediaItem> items;
  final String? serverUrl;
  final String? token;

  const _LibraryContentPage({
    required this.lib,
    required this.items,
    this.serverUrl,
    this.token,
  });

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
                  Text(
                    lib.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // 内容网格
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                // 海报按最大块宽自适应列数，避免宽屏下每张海报过大
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  // MediaCard 在海报下方还有标题行与 meta 行（约 44px），
                  // 沿用 2/3 会把海报挤压得偏离 2:3
                  childAspectRatio: 0.55,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final progress = item.userData?.progressPercent ?? 0;
                  return MediaCard(
                    item: item,
                    onTap: () => _openItem(context, item),
                    imageUrlBuilder: (id, {type = 'Primary', maxWidth}) =>
                        '${ApiClient.proxyBaseUrl}/api/images/$id/$type'
                        '${maxWidth != null ? '?maxWidth=$maxWidth' : ''}',
                    imageHeaders: {
                      'X-Emby-Server': serverUrl ?? '',
                      'X-Emby-Token': token ?? '',
                    },
                    progress: progress > 0 ? progress : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openItem(BuildContext context, MediaItem item) {
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
