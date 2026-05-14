import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../models/media_models.dart';
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
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final theme = Theme.of(context);
    final userName = authState.authResult?.user.name ?? '';

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          floating: true,
          title: Text(t.home.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(homeProvider.notifier).loadAll(),
            ),
          ],
        ),

        // Welcome
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Text(
              t.home.welcome(name: userName),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Loading
        if (homeState.isLoading && homeState.resumeItems.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // Continue Watching (Resume)
        if (homeState.resumeItems.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: t.home.continueWatching,
              items: homeState.resumeItems,
              serverUrl: _serverUrl,
              token: _token,
            ),
          ),

        // Error
        if (homeState.error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(homeState.error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),
                  ],
                ),
              ),
            ),
          ),

        // Media Libraries section
        if (homeState.libraries.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                '媒体库',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        if (homeState.libraries.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: homeState.libraries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final lib = homeState.libraries[index];
                  return _LibraryCard(
                    folder: lib,
                    serverUrl: _serverUrl,
                    token: _token,
                  );
                },
              ),
            ),
          ),

        // Per-library rows (only show libraries with items)
        for (final lib in homeState.libraries) ...[
          if (homeState.libraryItems.containsKey(lib.id) &&
              homeState.libraryItems[lib.id]!.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _MediaRow(
                title: lib.name,
                items: homeState.libraryItems[lib.id]!,
                serverUrl: _serverUrl,
                token: _token,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ],

        // Account section at the bottom
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 24),
                Text(
                  '账号',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                authState.authResult?.server.serverName ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _switchAccount(context, ref),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('切换账号'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // _serverUrl is now loaded in initState and stored in state
  String? get _token => ref.read(authProvider).authResult?.token;

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
                  MaterialPageRoute(builder: (_) => const ServerSelectionScreen()),
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

class _MediaRow extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final String? serverUrl;
  final String? token;

  const _MediaRow({
    required this.title,
    required this.items,
    this.serverUrl,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ItemCard(
                item: item,
                serverUrl: serverUrl,
                token: token,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final MediaItem item;
  final String? serverUrl;
  final String? token;

  const _ItemCard({
    required this.item,
    this.serverUrl,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = 'http://localhost:19800/api/images/${item.id}/Primary?maxWidth=300';

    return SizedBox(
      width: 130,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Widget destination;
            if (item.isSeries) {
              destination = SeriesDetailScreen(item: item);
            } else if (item.isEpisode) {
              destination = EpisodeDetailScreen(item: item);
            } else {
              destination = MediaDetailScreen(item: item);
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: item.hasPrimaryImage
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              headers: {
                                'Accept': 'image/*',
                                'X-Emby-Server': serverUrl ?? '',
                                'X-Emby-Token': token ?? '',
                              },
                              errorBuilder: (_, __, ___) => _placeholder(theme),
                            )
                          : _placeholder(theme),
                    ),
                    // Progress bar for resume items
                    if (item.userData != null && item.userData!.progressPercent > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: item.userData!.progressPercent,
                          backgroundColor: Colors.black45,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isEpisode ? '${item.seriesName} - ${item.episodeLabel}' : item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.productionYear > 0)
                          Text(
                            '${item.productionYear}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        if (item.communityRating > 0) ...[
                          if (item.productionYear > 0) const SizedBox(width: 6),
                          Icon(Icons.star_rounded, size: 12, color: Colors.amber.shade600),
                          const SizedBox(width: 1),
                          Text(
                            item.communityRating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Center(
      child: Icon(
        item.isMovie
            ? Icons.movie_outlined
            : item.isSeries
                ? Icons.tv_outlined
                : item.isEpisode
                    ? Icons.play_circle_outline
                    : Icons.video_file_outlined,
        size: 32,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final MediaFolder folder;
  final String? serverUrl;
  final String? token;

  const _LibraryCard({
    required this.folder,
    this.serverUrl,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = 'http://localhost:19800/api/images/${folder.id}/Primary?maxWidth=200';

    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 70,
                  height: double.infinity,
                  child: folder.hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          headers: {
                            'Accept': 'image/*',
                            'X-Emby-Server': serverUrl ?? '',
                            'X-Emby-Token': token ?? '',
                          },
                          errorBuilder: (_, __, ___) => _libPlaceholder(theme),
                        )
                      : _libPlaceholder(theme),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _typeLabel(folder.collectionType),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _libPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          _iconForType(folder.collectionType),
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          size: 24,
        ),
      ),
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
