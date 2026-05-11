import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_models.dart';
import '../providers/auth_provider.dart';

class MediaDetailScreen extends ConsumerStatefulWidget {
  final MediaItem item;

  const MediaDetailScreen({super.key, required this.item});

  @override
  ConsumerState<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends ConsumerState<MediaDetailScreen> {
  MediaStreamInfo? _streamInfo;
  List<MediaItem> _seasons = [];
  List<MediaItem> _episodes = [];
  String? _selectedSeasonId;
  bool _loadingStream = false;
  bool _loadingSeasons = false;
  bool _loadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadPlaybackInfo();
    if (widget.item.isSeries) {
      _loadSeasons();
    }
  }

  Future<void> _loadPlaybackInfo() async {
    final token = ref.read(authProvider).authResult?.token;
    final serverUrl = await ref.read(storageServiceProvider).getServerUrl();
    if (token == null || serverUrl == null) return;

    setState(() => _loadingStream = true);
    try {
      final info = await ref.read(apiClientProvider).getPlaybackInfo(
            serverUrl: serverUrl,
            token: token,
            itemId: widget.item.id,
          );
      if (mounted) setState(() => _streamInfo = info);
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingStream = false);
    }
  }

  Future<void> _loadSeasons() async {
    final token = ref.read(authProvider).authResult?.token;
    final serverUrl = await ref.read(storageServiceProvider).getServerUrl();
    if (token == null || serverUrl == null) return;

    setState(() => _loadingSeasons = true);
    try {
      final result = await ref.read(apiClientProvider).getSeasons(
            serverUrl: serverUrl,
            token: token,
            seriesId: widget.item.id,
          );
      if (mounted) {
        setState(() {
          _seasons = result.items;
          _loadingSeasons = false;
        });
        if (_seasons.isNotEmpty) {
          _loadEpisodes(_seasons.first.id);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSeasons = false);
    }
  }

  Future<void> _loadEpisodes(String seasonId) async {
    final token = ref.read(authProvider).authResult?.token;
    final serverUrl = await ref.read(storageServiceProvider).getServerUrl();
    if (token == null || serverUrl == null) return;

    setState(() {
      _loadingEpisodes = true;
      _selectedSeasonId = seasonId;
    });
    try {
      final result = await ref.read(apiClientProvider).getEpisodes(
            serverUrl: serverUrl,
            token: token,
            seriesId: widget.item.id,
            seasonId: seasonId,
          );
      if (mounted) {
        setState(() {
          _episodes = result.items;
          _loadingEpisodes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEpisodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final token = ref.read(authProvider).authResult?.token;
    final serverUrl = 'http://localhost:19800';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.hasBackdrop)
                    Image.network(
                      '$serverUrl/api/images/${item.id}/Backdrop?maxWidth=800',
                      fit: BoxFit.cover,
                      headers: {'Accept': 'image/*', 'X-Emby-Token': token ?? ''},
                      errorBuilder: (_, __, ___) => _buildHeaderFallback(theme),
                    )
                  else if (item.hasPrimaryImage)
                    Image.network(
                      '$serverUrl/api/images/${item.id}/Primary?maxWidth=600',
                      fit: BoxFit.cover,
                      headers: {'Accept': 'image/*', 'X-Emby-Token': token ?? ''},
                      errorBuilder: (_, __, ___) => _buildHeaderFallback(theme),
                    )
                  else
                    _buildHeaderFallback(theme),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meta row
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (item.productionYear > 0) _MetaChip(label: '${item.productionYear}'),
                      if (item.communityRating > 0)
                        _MetaChip(
                          label: item.communityRating.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber.shade600,
                        ),
                      if (item.officialRating.isNotEmpty) _MetaChip(label: item.officialRating),
                      if (item.durationText.isNotEmpty) _MetaChip(label: item.durationText),
                      if (item.type.isNotEmpty) _MetaChip(label: _typeLabel(item.type)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Genres
                  if (item.genres.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: item.genres
                          .map((g) => Chip(
                                label: Text(g, style: theme.textTheme.bodySmall),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Overview
                  if (item.overview.isNotEmpty) ...[
                    Text(
                      '简介',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.overview,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Seasons (for Series)
                  if (item.isSeries) ...[
                    Text(
                      '剧集',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingSeasons)
                      const Center(child: CircularProgressIndicator())
                    else if (_seasons.isNotEmpty) ...[
                      // Season selector
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _seasons.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final season = _seasons[index];
                            final isSelected = season.id == _selectedSeasonId;
                            return FilterChip(
                              label: Text(season.name),
                              selected: isSelected,
                              onSelected: (_) => _loadEpisodes(season.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Episodes list
                      if (_loadingEpisodes)
                        const Center(child: CircularProgressIndicator())
                      else
                        ..._episodes.map((ep) => _EpisodeTile(
                              episode: ep,
                              serverUrl: serverUrl,
                              token: token,
                            )),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Media streams
                  if (_loadingStream)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_streamInfo != null) ...[
                    // Video info
                    if (_videoStreams.isNotEmpty) ...[
                      _StreamSection(title: '视频', streams: _videoStreams),
                      const SizedBox(height: 16),
                    ],
                    // Audio info
                    if (_audioStreams.isNotEmpty) ...[
                      _StreamSection(title: '音频', streams: _audioStreams),
                      const SizedBox(height: 16),
                    ],
                    // Subtitle info
                    if (_subtitleStreams.isNotEmpty) ...[
                      _StreamSection(title: '字幕', streams: _subtitleStreams),
                      const SizedBox(height: 16),
                    ],
                    // Container info
                    if (_streamInfo!.mediaSources.isNotEmpty) ...[
                      _StreamSection(
                        title: '源信息',
                        streams: [],
                        container: _streamInfo!.mediaSources.first.container,
                        bitrate: _streamInfo!.mediaSources.first.bitrate,
                        size: _streamInfo!.mediaSources.first.size,
                      ),
                    ],
                  ],

                  // Series info (for episodes)
                  if (item.seriesName.isNotEmpty && !item.isSeries) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.tv, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.seriesName, style: theme.textTheme.titleSmall),
                                  if (item.episodeLabel.isNotEmpty)
                                    Text(
                                      item.episodeLabel,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // User data (playback progress)
                  if (item.userData != null && item.userData!.playCount > 0) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              item.userData!.played ? Icons.check_circle : Icons.play_circle,
                              size: 20,
                              color: item.userData!.played
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.userData!.played ? '已观看' : '已观看 ${item.userData!.playCount} 次',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (item.userData!.progressPercent > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: LinearProgressIndicator(
                                        value: item.userData!.progressPercent,
                                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MediaStream> get _videoStreams =>
      _streamInfo?.mediaSources.expand((s) => s.mediaStreams).where((s) => s.isVideo).toList() ?? [];

  List<MediaStream> get _audioStreams =>
      _streamInfo?.mediaSources.expand((s) => s.mediaStreams).where((s) => s.isAudio).toList() ?? [];

  List<MediaStream> get _subtitleStreams =>
      _streamInfo?.mediaSources.expand((s) => s.mediaStreams).where((s) => s.isSubtitle).toList() ?? [];

  Widget _buildHeaderFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.movie_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'Movie': return '电影';
      case 'Series': return '剧集';
      case 'Episode': return '剧集';
      case 'Audio': return '音乐';
      default: return type;
    }
  }
}

class _EpisodeTile extends StatelessWidget {
  final MediaItem episode;
  final String serverUrl;
  final String? token;

  const _EpisodeTile({
    required this.episode,
    required this.serverUrl,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = '$serverUrl/api/images/${episode.id}/Primary?maxWidth=200';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 80,
            height: 45,
            child: episode.hasPrimaryImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    headers: {'Accept': 'image/*', 'X-Emby-Token': token ?? ''},
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.play_circle_outline, size: 20)),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.play_circle_outline, size: 20)),
                  ),
          ),
        ),
        title: Text(
          '${episode.episodeLabel} ${episode.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: episode.overview.isNotEmpty
            ? Text(
                episode.overview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              )
            : null,
        trailing: episode.durationText.isNotEmpty
            ? Text(
                episode.durationText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              )
            : null,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _MetaChip({required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StreamSection extends StatelessWidget {
  final String title;
  final List<MediaStream> streams;
  final String? container;
  final int? bitrate;
  final int? size;

  const _StreamSection({
    required this.title,
    required this.streams,
    this.container,
    this.bitrate,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...streams.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  if (s.displayTitle.isNotEmpty)
                    Expanded(
                      child: Text(
                        s.displayTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else ...[
                    if (s.codec.isNotEmpty)
                      Text(
                        s.codec.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    if (s.resolution.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        s.resolution,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    if (s.language.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        s.language,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            )),
        if (container != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 12,
              children: [
                if (container!.isNotEmpty)
                  Text(
                    container!.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                if (bitrate != null && bitrate! > 0)
                  Text(
                    '${(bitrate! / 1000000).toStringAsFixed(1)} Mbps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                if (size != null && size! > 0)
                  Text(
                    _formatSize(size!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
