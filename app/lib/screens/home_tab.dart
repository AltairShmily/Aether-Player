import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../models/media_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_breakpoints.dart';
import '../widgets/aether_card.dart';
import '../widgets/aether_button.dart';
import '../widgets/aether_hero.dart';
import '../widgets/aether_progress.dart';
import '../widgets/aether_badge.dart';
import '../widgets/aether_chip.dart';
import '../widgets/glass_panel.dart';
import '../widgets/scroll_arrows.dart';
import 'series_detail_screen.dart';
import 'episode_detail_screen.dart';
import 'media_detail_screen.dart';
import 'server_selection_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String? _serverUrl;
  final PageController _heroController = PageController(viewportFraction: 0.92);

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

    return CustomScrollView(
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
            child: SizedBox(
              height: AetherBreakpoints.heroHeight(context),
              child: PageView.builder(
                controller: _heroController,
                itemCount: homeState.resumeItems.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final item = homeState.resumeItems[index];
                  final imageUrl =
                      'http://localhost:19800/api/images/${item.id}/Backdrop?maxWidth=800';
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
                        onPressed: () => _navigateToItem(context, item),
                      ),
                      onTap: () => _navigateToItem(context, item),
                    ),
                  );
                },
              ),
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

        // ── Per-library rows ──
        for (final lib in homeState.libraries) ...[
          if (homeState.libraryItems.containsKey(lib.id) &&
              homeState.libraryItems[lib.id]!.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionRow(
                title: lib.name,
                items: homeState.libraryItems[lib.id]!,
                serverUrl: _serverUrl,
                token: token,
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
    );
  }

  void _navigateToItem(BuildContext context, MediaItem item) {
    Widget destination;
    if (item.isSeries) {
      destination = SeriesDetailScreen(series: item);
    } else if (item.isEpisode) {
      destination = EpisodeDetailScreen(item: item);
    } else {
      destination = MediaDetailScreen(item: item);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
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
                  MaterialPageRoute(
                      builder: (_) => const ServerSelectionScreen()),
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
}

// ══════════════════════════════════════════════════
//  _SectionRow — 杂志感分类行
// ══════════════════════════════════════════════════
class _SectionRow extends StatefulWidget {
  final String title;
  final List<MediaItem> items;
  final String? serverUrl;
  final String? token;

  const _SectionRow({
    required this.title,
    required this.items,
    this.serverUrl,
    this.token,
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
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                '查看全部 ›',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
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
                return _HomeItemCard(
                  item: item,
                  serverUrl: widget.serverUrl,
                  token: widget.token,
                  height: cardH,
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
//  _HomeItemCard — 星辉卡片
// ══════════════════════════════════════════════════
class _HomeItemCard extends StatelessWidget {
  final MediaItem item;
  final String? serverUrl;
  final String? token;
  final double height;

  const _HomeItemCard({
    required this.item,
    this.serverUrl,
    this.token,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = height * 0.68;
    final imageUrl =
        'http://localhost:19800/api/images/${item.id}/Primary?maxWidth=300';

    return SizedBox(
      width: cardW,
      child: AetherCard.simple(
        onTap: () {
          Widget dest;
          if (item.isSeries) {
            dest = SeriesDetailScreen(series: item);
          } else if (item.isEpisode) {
            dest = EpisodeDetailScreen(item: item);
          } else {
            dest = MediaDetailScreen(item: item);
          }
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => dest));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 海报区
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.stardust,
                      child: item.hasPrimaryImage
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              headers: {
                                'Accept': 'image/*',
                                'X-Emby-Server': serverUrl ?? '',
                                'X-Emby-Token': token ?? '',
                              },
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    // 进度条
                    if (item.userData != null &&
                        item.userData!.progressPercent > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AetherProgress.mini(
                          value: item.userData!.progressPercent,
                        ),
                      ),
                    // 评分角标
                    if (item.communityRating > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: AetherBadge.rating(score: item.communityRating),
                      ),
                  ],
                ),
              ),
            ),
            // 信息区
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isEpisode
                        ? '${item.seriesName} - ${item.episodeLabel}'
                        : item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (item.productionYear > 0)
                        Text(
                          '${item.productionYear}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        item.isMovie
            ? Icons.movie_outlined
            : item.isSeries
                ? Icons.tv_outlined
                : Icons.play_circle_outline,
        size: 32,
        color: AppColors.cosmicGray,
      ),
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
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '媒体库',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
