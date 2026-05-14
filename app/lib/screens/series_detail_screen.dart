import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../widgets/diamond_badge.dart';
import '../widgets/pill_button.dart';
import '../widgets/genre_chip.dart';
import '../widgets/episode_card.dart';
import '../models/media_models.dart';
import '../providers/auth_provider.dart';
import 'episode_detail_screen.dart';

/// 剧集总览页 - 展示 TV 系列的所有季与集
///
/// 路由参数: 接收一个 type=='Series' 的 MediaItem
/// 页面结构:
///   1. Hero 背景图 + 渐变遮罩
///   2. 菱形徽章 (系列首字母/季数)
///   3. 标题 / 年份 / 评分 / 类型标签
///   4. 简介
///   5. 季选择器 (横向滚动 FilterChip)
///   6. 本季集数列表 (EpisodeCard 横向 + EpisodeTile 纵向)
///   7. 演员表
class SeriesDetailScreen extends ConsumerStatefulWidget {
  final MediaItem series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  List<MediaItem> _seasons = [];
  List<MediaItem> _episodes = [];
  String? _selectedSeasonId;
  bool _loadingSeasons = false;
  bool _loadingEpisodes = false;

  static const _serverUrl = 'http://localhost:19800';

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  // ── Data loading ──────────────────────────────────────────────

  Future<void> _loadSeasons() async {
    final token = ref.read(authProvider).authResult?.token;
    final serverUrl = await ref.read(storageServiceProvider).getServerUrl();
    if (token == null || serverUrl == null) return;

    setState(() => _loadingSeasons = true);
    try {
      final userId = ref.read(authProvider).authResult?.user.id ?? '';
      final result = await ref.read(apiClientProvider).getSeasons(
            serverUrl: serverUrl,
            token: token,
            userId: userId,
            seriesId: widget.series.id,
          );
      if (!mounted) return;
      setState(() {
        _seasons = result.items;
        _loadingSeasons = false;
      });
      if (_seasons.isNotEmpty) {
        _loadEpisodes(_seasons.first.id);
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
      final userId = ref.read(authProvider).authResult?.user.id ?? '';
      final result = await ref.read(apiClientProvider).getEpisodes(
            serverUrl: serverUrl,
            token: token,
            userId: userId,
            seriesId: widget.series.id,
            seasonId: seasonId,
          );
      if (!mounted) return;
      setState(() {
        _episodes = result.items;
        _loadingEpisodes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEpisodes = false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────

  void _onEpisodeTap(MediaItem episode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EpisodeDetailScreen(item: episode),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final token = ref.read(authProvider).authResult?.token;

    return Scaffold(
      backgroundColor: AppColors.seriesBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero image ──
          _buildHeroAppBar(series, token),

          // ── Content ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleSection(series),
                _buildOverview(series),
                _buildSeasonSelector(),
                _buildEpisodeList(series, token),
                _buildCastSection(series, token),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero AppBar ───────────────────────────────────────────────

  Widget _buildHeroAppBar(MediaItem series, String? token) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.seriesBg,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (series.hasBackdrop)
              Image.network(
                '$_serverUrl/api/images/${series.id}/Backdrop?maxWidth=800',
                fit: BoxFit.cover,
                headers: {'Accept': 'image/*', 'X-Emby-Token': token ?? ''},
                errorBuilder: (_, __, ___) => _heroFallback(),
              )
            else if (series.hasPrimaryImage)
              Image.network(
                '$_serverUrl/api/images/${series.id}/Primary?maxWidth=600',
                fit: BoxFit.cover,
                headers: {'Accept': 'image/*', 'X-Emby-Token': token ?? ''},
                errorBuilder: (_, __, ___) => _heroFallback(),
              )
            else
              _heroFallback(),
            // Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.seriesBg],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      color: AppColors.seriesBg,
      child: const Center(
        child: Icon(Icons.tv, size: 64, color: AppColors.textSecondary),
      ),
    );
  }

  // ── Title section ─────────────────────────────────────────────

  Widget _buildTitleSection(MediaItem series) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diamond badge + Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiamondBadge(
                title: series.childCount != null
                    ? '${series.childCount}季'
                    : series.name.length > 4
                        ? series.name.substring(0, 4)
                        : series.name,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status tag
                    if (series.status != null && series.status!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: series.status == 'Continuing'
                              ? AppColors.playMint.withValues(alpha: 0.2)
                              : AppColors.textSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          series.status == 'Continuing' ? '连载中' : '已完结',
                          style: TextStyle(
                            color: series.status == 'Continuing'
                                ? AppColors.playMint
                                : AppColors.textWarmGray,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Meta chips row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (series.productionYear > 0)
                _MetaChip(label: '${series.productionYear}'),
              if (series.communityRating > 0)
                _MetaChip(
                  label: series.communityRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  iconColor: AppColors.ratingStar,
                ),
              if (series.officialRating.isNotEmpty)
                _MetaChip(label: series.officialRating),
            ],
          ),
          const SizedBox(height: 14),

          // Genre chips
          if (series.genres.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: series.genres.map((g) => GenreChip(label: g)).toList(),
            ),
          const SizedBox(height: 20),

          // Play button
          PillButton(
            icon: Icons.play_arrow_rounded,
            label: '播放',
            backgroundColor: AppColors.playMint,
            showMenuIcon: false,
            onPressed: () {
              // TODO: Start playing first unwatched episode or first episode
              if (_episodes.isNotEmpty) {
                _onEpisodeTap(_episodes.first);
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Overview ──────────────────────────────────────────────────

  Widget _buildOverview(MediaItem series) {
    if (series.overview.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '简介',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            series.overview,
            style: const TextStyle(
              color: AppColors.textWarmGray,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Season selector ───────────────────────────────────────────

  Widget _buildSeasonSelector() {
    if (_loadingSeasons && _seasons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.playMint),
        ),
      );
    }
    if (_seasons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text(
                  '季数',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_seasons.length}',
                  style: const TextStyle(
                    color: AppColors.textCoolGray,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal season chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _seasons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final season = _seasons[index];
                final isSelected = season.id == _selectedSeasonId;
                return GestureDetector(
                  onTap: () => _loadEpisodes(season.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.playMint : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.playMint
                            : AppColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      season.name,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.seriesBg
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Episode list ──────────────────────────────────────────────

  Widget _buildEpisodeList(MediaItem series, String? token) {
    if (_loadingEpisodes && _episodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.playMint),
        ),
      );
    }
    if (_episodes.isEmpty) return const SizedBox.shrink();

    // Determine the selected season name for header
    final selectedSeason = _seasons.where((s) => s.id == _selectedSeasonId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  selectedSeason?.name ?? '集数',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_episodes.length}集',
                  style: const TextStyle(
                    color: AppColors.textCoolGray,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scroll preview (first 10 episodes)
          if (_episodes.length > 1)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _episodes.length.clamp(0, 10),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final ep = _episodes[index];
                  return EpisodeCard(
                    imageUrl: ep.hasPrimaryImage
                        ? '$_serverUrl/api/images/${ep.id}/Primary?maxWidth=200'
                        : null,
                    title: ep.episodeLabel.isNotEmpty ? ep.episodeLabel : ep.name,
                    subtitle: ep.name,
                    progress: ep.userData?.progressPercent,
                    token: token,
                    onTap: () => _onEpisodeTap(ep),
                  );
                },
              ),
            ),

          // Full episode list
          const SizedBox(height: 16),
          ..._episodes.map((ep) => _EpisodeTile(
                episode: ep,
                serverUrl: _serverUrl,
                token: token,
                onTap: () => _onEpisodeTap(ep),
              )),
        ],
      ),
    );
  }

  // ── Cast section ──────────────────────────────────────────────

  Widget _buildCastSection(MediaItem series, String? token) {
    if (series.actors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '演员',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: series.actors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final actor = series.actors[index];
                return _CastMember(
                  name: actor.name,
                  role: actor.role,
                  personId: actor.id,
                  serverUrl: _serverUrl,
                  token: token,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════════════

/// Meta info chip (year, rating, etc.)
class _MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _MetaChip({required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Episode tile for the full list view
class _EpisodeTile extends StatelessWidget {
  final MediaItem episode;
  final String serverUrl;
  final String? token;
  final VoidCallback? onTap;

  const _EpisodeTile({
    required this.episode,
    required this.serverUrl,
    this.token,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = '$serverUrl/api/images/${episode.id}/Primary?maxWidth=200';
    final hasProgress = episode.userData != null && episode.userData!.playedPercentage > 0;
    final isWatched = episode.userData?.played == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  SizedBox(
                    width: 100,
                    height: 56,
                    child: episode.hasPrimaryImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            headers: token != null ? {'X-Emby-Token': token!} : null,
                            errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                          )
                        : _thumbPlaceholder(),
                  ),
                  // Play icon overlay
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  // Progress bar
                  if (hasProgress)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: episode.userData!.progressPercent,
                        backgroundColor: Colors.black45,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.playMint),
                        minHeight: 3,
                      ),
                    ),
                  // Watched badge
                  if (isWatched)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.playMint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.check, size: 10, color: AppColors.seriesBg),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode label + title
                  Text(
                    '${episode.episodeLabel} ${episode.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isWatched ? AppColors.textWarmGray : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (episode.overview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      episode.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWarmGray,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Duration
            if (episode.durationFormatted.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                episode.durationFormatted,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 100,
      height: 56,
      color: AppColors.cardBg,
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Cast member widget (avatar + name + role)
class _CastMember extends StatelessWidget {
  final String name;
  final String? role;
  final String? personId;
  final String serverUrl;
  final String? token;

  const _CastMember({
    required this.name,
    this.role,
    this.personId,
    required this.serverUrl,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.cardBg,
            child: personId != null && personId!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      '$serverUrl/api/images/$personId/Primary?maxWidth=80',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      headers: token != null ? {'X-Emby-Token': token!} : null,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 24,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
          ),
          if (role != null && role!.isNotEmpty)
            Text(
              role!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textWarmGray, fontSize: 10),
            ),
        ],
      ),
    );
  }
}
