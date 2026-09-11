import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../utils/episode_utils.dart';
import '../widgets/meta_chip.dart';
import '../widgets/diamond_badge.dart';
import '../widgets/pill_button.dart';
import '../widgets/aether_chip.dart';
import '../widgets/episode_card.dart';
import '../widgets/skeleton_loader.dart';
import '../models/media_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../widgets/aether_page_route.dart';
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
  List<MergedEpisode> _episodes = [];
  String? _selectedSeasonId;
  bool _loadingSeasons = false;
  bool _loadingEpisodes = false;
  String _embyServerUrl = '';

  /// Emby 服务器地址是否已读取完毕。
  /// 图片请求依赖它作为 X-Emby-Server 头，就绪前渲染会导致图片永久失败
  bool _contextLoaded = false;


  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  // ── Data loading ──────────────────────────────────────────────

  Future<void> _loadSeasons() async {
    final token = ref.read(authProvider).authResult?.token;
    final serverUrl = await ref.read(storageServiceProvider).getServerUrl();

    // 无论后续能否加载，都要标记上下文已就绪：
    // 若在此提前 return 而不置位，build 的门控会永远停在加载态
    if (mounted) {
      setState(() {
        _embyServerUrl = serverUrl ?? '';
        _contextLoaded = true;
        _loadingSeasons = true;
      });
    }

    if (token == null || serverUrl == null) return;

    try {
      final userId = ref.read(authProvider).authResult?.user.id ?? '';
      final result = await ref
          .read(apiClientProvider)
          .getSeasons(
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
      final result = await ref
          .read(apiClientProvider)
          .getEpisodes(
            serverUrl: serverUrl,
            token: token,
            userId: userId,
            seriesId: widget.series.id,
            seasonId: seasonId,
          );
      if (!mounted) return;
      setState(() {
        _episodes = mergeEpisodes(result.items);
        _loadingEpisodes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEpisodes = false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────

  void _onEpisodeTap(MediaItem episode) {
    Navigator.of(context).push(
      AetherPageRoute(
        page: EpisodeDetailScreen(item: episode),
        type: AetherTransitionType.slideFromRight,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final token = ref.read(authProvider).authResult?.token;

    // 图片请求依赖 X-Emby-Server 头指向真实 Emby 地址，而该值是异步读取的，
    // 首帧为空串。带空头的请求会被本地代理拒绝（502），而 NetworkImage 的
    // 相等性只比较 url 与 scale、不含 headers，地址补上后也不会重新解析，
    // 图片将永久停留在失败态。故在就绪前不渲染任何图片内容。
    if (!_contextLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.seriesBg,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.celestialCyan,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.seriesBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero image ──
          _buildHeroAppBar(series, token),

          // ── Content with poster overlap ──
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Poster overlapping the hero backdrop
                Positioned(
                  left: 16,
                  top: -70,
                  child: Container(
                    width: 170,
                    height: 255,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0x1F00D4FF),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      child: series.hasPrimaryImage
                          ? Image.network(
                              ApiClient.imageProxyUrl(series.id, maxWidth: 400),
                              fit: BoxFit.cover,
                              headers: {
                                'Accept': 'image/*',
                                'X-Emby-Token': token ?? '',
                                'X-Emby-Server': _embyServerUrl,
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.cardBg,
                                child: const Center(
                                  child: Icon(
                                    Icons.tv,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.cardBg,
                              child: const Center(
                                child: Icon(
                                  Icons.tv,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                // Main content column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 185,
                    ), // 255 - 70 = space below hero for poster
                    _buildTitleSection(series),
                    _buildOverview(series),
                    _buildSeasonSelector(),
                    _buildEpisodeList(series, token),
                    _buildCastSection(series, token),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero AppBar ───────────────────────────────────────────────

  Widget _buildHeroAppBar(MediaItem series, String? token) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            // Rounded hero backdrop card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusXl),
                child: SizedBox(
                  height: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (series.hasBackdrop)
                        Image.network(
                          ApiClient.imageProxyUrl(series.id, type: 'Backdrop', maxWidth: 800),
                          fit: BoxFit.cover,
                          headers: {
                            'Accept': 'image/*',
                            'X-Emby-Token': token ?? '',
                            'X-Emby-Server': _embyServerUrl,
                          },
                          errorBuilder: (_, __, ___) => _heroFallback(),
                        )
                      else if (series.hasPrimaryImage)
                        Image.network(
                          ApiClient.imageProxyUrl(series.id, maxWidth: 600),
                          fit: BoxFit.cover,
                          headers: {
                            'Accept': 'image/*',
                            'X-Emby-Token': token ?? '',
                            'X-Emby-Server': _embyServerUrl,
                          },
                          errorBuilder: (_, __, ___) => _heroFallback(),
                        )
                      else
                        _heroFallback(),
                      // Gradient overlay (dual layer: to top + to right)
                      // HTML: linear-gradient(to top, var(--bg-primary) 5%, transparent 50%)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.bgPrimary],
                            stops: const [0.50, 1.0],
                          ),
                        ),
                      ),
                      // HTML: linear-gradient(to right, rgba(10,14,20,0.7), transparent 60%)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.deepVoid.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Back button (on top of backdrop)
            //
            // body 没有 SafeArea，hero 区从屏幕最顶端开始，
            // 因此按钮必须自行避开状态栏/刘海，否则会被系统 UI 遮挡而点不到
            Positioned(
              top: 12 + MediaQuery.paddingOf(context).top,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.nebulaDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
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

  /// 主播放按钮的目标集 —— 按进度选集，规则见 [pickResumeEpisode]
  ResumeTarget? get _resumeTarget => pickResumeEpisode(_episodes);

  /// 目标集的 SxxExx 标签；缺失时为空串，按钮文案会退化为不带集号
  String get _resumeLabel =>
      _resumeTarget?.episode.primary.episodeLabel ?? '';

  /// 「继续观看」条的内容：有未看完进度的集，最多 3 集。
  ///
  /// 判定条件与 [pickResumeEpisode] 一致（有播放位置且未标记看完），
  /// 避免主按钮指向的集不出现在继续观看条里。
  List<MergedEpisode> get _continueWatching => _episodes
      .where((m) {
        final ud = m.primary.userData;
        return ud != null && ud.playbackPositionTicks > 0 && !ud.played;
      })
      .take(3)
      .toList();

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
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.03,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status tag
                    if (series.status != null && series.status!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                MetaChip(
                  label: '${series.productionYear}',
                  backgroundColor: AppColors.cardBg,
                  textStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (series.communityRating > 0)
                MetaChip(
                  label: series.communityRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  iconColor: AppColors.ratingStar,
                  backgroundColor: AppColors.accentSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  textStyle: const TextStyle(
                    color: AppColors.celestialCyan,
                    fontSize: 10.9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (series.officialRating.isNotEmpty)
                MetaChip(
                  label: series.officialRating,
                  backgroundColor: AppColors.cardBg,
                  textStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Genre chips
          if (series.genres.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: series.genres
                  .map((g) => AetherChip.genre(label: g))
                  .toList(),
            ),
          const SizedBox(height: 20),

          // Play button —— 按进度选集，而非固定播第一集
          if (_resumeTarget != null)
            PillButton(
              icon: Icons.play_arrow_rounded,
              label: _resumeTarget!.hasProgress
                  ? (_resumeLabel.isNotEmpty
                      ? '继续播放 $_resumeLabel'
                      : '继续播放')
                  : (_resumeLabel.isNotEmpty ? '播放 $_resumeLabel' : '播放'),
              backgroundColor: AppColors.playMint,
              showMenuIcon: false,
              onPressed: () => _onEpisodeTap(_resumeTarget!.episode.primary),
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              series.overview,
              style: const TextStyle(
                color: AppColors.textWarmGray,
                fontSize: 11.9,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Season selector (underline-tab style) ─────────────────────

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
      padding: const EdgeInsets.only(top: 24, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab row with underline indicator
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: _seasons.map((season) {
                  final isSelected = season.id == _selectedSeasonId;
                  return GestureDetector(
                    onTap: () => _loadEpisodes(season.id),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 18,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              season.name,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.celestialCyan
                                    : AppColors.textTertiary,
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Animated underline indicator (scaleX)
                            // HTML: left:0; right:0; height:2px; full-width
                            AnimatedScale(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              scale: isSelected ? 1.0 : 0.0,
                              alignment: Alignment.center,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Episode list ──────────────────────────────────────────────

  /// 剧集加载骨架：3 行 Tile（缩略图 130×73 + 两条灰条）。
  ///
  /// 复用共享的 [AetherSkeleton]，不再各页自绘加载态。
  Widget _buildEpisodeSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: List.generate(3, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                const AetherSkeleton(width: 130, height: 73, borderRadius: 8),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AetherSkeleton.text(width: 160),
                      SizedBox(height: 8),
                      AetherSkeleton.text(width: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 空季提示。原先直接返回 SizedBox.shrink()，
  /// 用户无法区分「本季确实没有剧集」与「请求失败或还没请求」。
  Widget _buildEmptyEpisodes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.video_library_outlined,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text(
              '本季还没有剧集',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadSeasons,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('刷新'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.celestialCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeList(MediaItem series, String? token) {
    if (_loadingEpisodes && _episodes.isEmpty) {
      return _buildEpisodeSkeleton();
    }
    if (_episodes.isEmpty) {
      return _buildEmptyEpisodes();
    }

    // Determine the selected season name for header
    final selectedSeason = _seasons
        .where((s) => s.id == _selectedSeasonId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with Material icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(
                  Icons.view_list_rounded,
                  size: 20,
                  color: AppColors.celestialCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedSeason?.name ?? '集数',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
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

          // ── 继续观看条 ──
          // 原先这里横向展示前 10 集，与下方纵向全量列表完全重复，
          // 白占首屏约 140px。改为只展示有未看完进度的集（≤3），
          // 无进度时整条不渲染，把首屏让给纵向列表。
          if (_continueWatching.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.play_circle_outline_rounded,
                      size: 18, color: AppColors.playMint),
                  SizedBox(width: 8),
                  Text(
                    '继续观看',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _continueWatching.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final ep = _continueWatching[index].primary;
                  return EpisodeCard(
                    imageUrl: ep.hasPrimaryImage
                        ? ApiClient.imageProxyUrl(ep.id, maxWidth: 200)
                        : null,
                    title: ep.episodeLabel.isNotEmpty
                        ? ep.episodeLabel
                        : ep.name,
                    subtitle: ep.name,
                    progress: ep.userData?.progressPercent,
                    token: token,
                    // 必须传：EpisodeCard 用它填 X-Emby-Server 头，
                    // 缺失时代理无法定位上游而返回 502，缩略图全部加载失败
                    serverUrl: _embyServerUrl,
                    onTap: () => _onEpisodeTap(ep),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Full episode list
          const SizedBox(height: 16),
          ..._episodes.map(
            (merged) => _EpisodeTile(
              episode: merged.primary,
              token: token,
              embyServerUrl: _embyServerUrl,
              versions: merged.hasMultipleVersions ? merged.versions : null,
              // 与主播放按钮的目标集比对，保证高亮与按钮指向一致
              isResumeTarget:
                  _resumeTarget?.episode.primary.id == merged.primary.id,
              onTap: () => _onEpisodeTap(merged.primary),
            ),
          ),
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
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                size: 20,
                color: AppColors.celestialCyan,
              ),
              const SizedBox(width: 8),
              const Text(
                '演员',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: series.actors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final actor = series.actors[index];
                return _CastMember(
                  name: actor.name,
                  role: actor.role,
                  personId: actor.id,
                  token: token,
                  embyServerUrl: _embyServerUrl,
                  index: index,
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

/// Episode tile for the full list view
class _EpisodeTile extends StatefulWidget {
  final MediaItem episode;
  final String? token;
  final String embyServerUrl;
  final List<EpisodeVersion>? versions;
  final VoidCallback? onTap;

  /// 是否为「接着看」目标集 —— 主播放按钮会播这一集，
  /// 用青色左边线高亮，让用户一眼看出按钮指向哪里
  final bool isResumeTarget;

  const _EpisodeTile({
    required this.episode,
    this.token,
    required this.embyServerUrl,
    this.versions,
    this.onTap,
    this.isResumeTarget = false,
  });

  @override
  State<_EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends State<_EpisodeTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        ApiClient.imageProxyUrl(widget.episode.id, maxWidth: 200);
    final hasProgress =
        widget.episode.userData != null &&
        widget.episode.userData!.playedPercentage > 0;
    final isWatched = widget.episode.userData?.played == true;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isResumeTarget
                ? AppColors.accentSoft
                : (_isHovered ? AppColors.surfaceHover : Colors.transparent),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            // 青色左边线标示主播放按钮指向的那一集
            border: widget.isResumeTarget
                ? const Border(
                    left: BorderSide(color: AppColors.celestialCyan, width: 2),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Thumbnail with hover play icon
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 73,
                      child: widget.episode.hasPrimaryImage
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              headers: widget.token != null
                                  ? {
                                      'X-Emby-Token': widget.token!,
                                      'X-Emby-Server': widget.embyServerUrl,
                                    }
                                  : null,
                              errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                            )
                          : _thumbPlaceholder(),
                    ),
                    // Play icon overlay (appears on hover)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle,
                              color: AppColors.celestialCyan,
                              size: 28,
                            ),
                          ),
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
                          value: widget.episode.userData!.progressPercent,
                          backgroundColor: Colors.black45,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.playMint,
                          ),
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
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: AppColors.seriesBg,
                          ),
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
                    Row(
                      children: [
                        if (widget.episode.episodeLabel.isNotEmpty)
                          Text(
                            '${widget.episode.episodeLabel} ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isWatched
                                  ? AppColors.textWarmGray
                                  : AppColors.textPrimary,
                              fontSize: 10.9,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'DM Mono',
                            ),
                          ),
                        Expanded(
                          child: Text(
                            widget.episode.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isWatched
                                  ? AppColors.textWarmGray
                                  : AppColors.textPrimary,
                              fontSize: 11.9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Version count badge
                    if (widget.versions != null &&
                        widget.versions!.length > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.celestialCyan.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.versions!.length} 版本',
                          style: const TextStyle(
                            color: AppColors.celestialCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (widget.episode.overview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.episode.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Duration
              if (widget.episode.durationFormatted.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  widget.episode.durationFormatted,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10.5,
                    fontFamily: 'DM Mono',
                  ),
                ),
              ],
            ],
          ),
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
        child: Icon(
          Icons.play_circle_outline,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Cast member widget (avatar + name + role)
class _CastMember extends StatelessWidget {
  final String name;
  final String? role;
  final String? personId;
  final String? token;
  final String embyServerUrl;
  final int index;

  // Gradient palette cycling through actor indices
  static const _gradientPalette = [
    [AppColors.celestialCyan, AppColors.novaPurple], // 0
    [AppColors.plasmaPink, AppColors.novaPurple], // 1
    [AppColors.auroraGreen, AppColors.celestialCyan], // 2
    [AppColors.supernova, AppColors.supernova], // 3
  ];

  const _CastMember({
    required this.name,
    this.role,
    this.personId,
    this.token,
    required this.embyServerUrl,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientPalette[index % _gradientPalette.length];

    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: AppColors.cardBg,
            child: personId != null && personId!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      ApiClient.imageProxyUrl(personId!, maxWidth: 80),
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      headers: token != null
                          ? {
                              'X-Emby-Token': token!,
                              'X-Emby-Server': embyServerUrl,
                            }
                          : null,
                      errorBuilder: (_, __, ___) => _gradientFallback(gradient),
                    ),
                  )
                : _gradientFallback(gradient),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9.5,
            ),
          ),
          if (role != null && role!.isNotEmpty)
            Text(
              role!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 8.7,
              ),
            ),
        ],
      ),
    );
  }

  Widget _gradientFallback(List<Color> colors) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
    );
  }
}
