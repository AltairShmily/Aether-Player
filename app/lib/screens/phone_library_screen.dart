import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_breakpoints.dart';
import '../models/media_models.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/aether_page_route.dart';
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
    if (oldWidget.selectedLibId != widget.selectedLibId && widget.selectedLibId != null) {
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 16 / 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lib = homeState.libraries[index];
                return _buildLibCard(lib);
              },
              childCount: homeState.libraries.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLibCard(MediaFolder lib) {
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

    return GestureDetector(
      onTap: () {
        // 通知父组件选中了这个库
        // 如果在 PhoneLibraryScreen 内部点击，直接显示内容
        if (widget.selectedLibId == null) {
          // 在 ShellScreen 中，需要通过回调更新状态
          // 这里我们直接用 Navigator.push 显示内容
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
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.nebulaDark,
              AppColors.stardust,
            ],
          ),
        ),
        child: Stack(
          children: [
            // 渐变遮罩
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.deepVoid.withValues(alpha: 0.6),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    lib.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '点击查看',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
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

  Widget _buildLibraryContent(HomeState homeState, String selectedId, double pad) {
    final items = homeState.libraryItems[selectedId] ?? [];
    final lib = homeState.libraries.firstWhere(
      (l) => l.id == selectedId,
      orElse: () => MediaFolder(
        id: '',
        name: '',
        collectionType: '',
      ),
    );

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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 2 / 3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return _buildMediaCard(item);
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    final imageUrl =
        '$_serverUrl/api/images/${item.id}/Primary?maxWidth=300';

    return GestureDetector(
      onTap: () {
        Widget dest;
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
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
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
                              'X-Emby-Server': _serverUrl ?? '',
                              'X-Emby-Token': _token ?? '',
                            },
                            errorBuilder: (_, __, ___) => _placeholder(item),
                          )
                        : _placeholder(item),
                  ),
                  // 底部渐变
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.deepVoid.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 标题
                  Positioned(
                    bottom: 6,
                    left: 8,
                    right: 8,
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 评分
                  if (item.communityRating > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.celestialCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.communityRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.celestialCyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(MediaItem item) {
    return Center(
      child: Icon(
        item.isMovie
            ? Icons.movie_outlined
            : item.isSeries
                ? Icons.tv_outlined
                : Icons.play_circle_outline,
        size: 28,
        color: AppColors.cosmicGray,
      ),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2 / 3,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final imageUrl = serverUrl != null
                      ? '$serverUrl/api/images/${item.id}/Primary?maxWidth=300'
                      : null;

                  return GestureDetector(
                    onTap: () {
                      Widget dest;
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
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppColors.radiusSm),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: AppColors.stardust,
                                  child: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          headers: {
                                            'Accept': 'image/*',
                                            'X-Emby-Server': serverUrl ?? '',
                                            'X-Emby-Token': token ?? '',
                                          },
                                          errorBuilder: (_, __, ___) => _placeholder(item),
                                        )
                                      : _placeholder(item),
                                ),
                                // 底部渐变
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          AppColors.deepVoid.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // 标题
                                Positioned(
                                  bottom: 6,
                                  left: 8,
                                  right: 8,
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(MediaItem item) {
    return Center(
      child: Icon(
        item.isMovie
            ? Icons.movie_outlined
            : item.isSeries
                ? Icons.tv_outlined
                : Icons.play_circle_outline,
        size: 28,
        color: AppColors.cosmicGray,
      ),
    );
  }
}
