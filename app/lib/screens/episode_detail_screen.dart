import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_breakpoints.dart';
import '../widgets/diamond_badge.dart';
import '../widgets/pill_button.dart';
import '../widgets/media_info_card.dart';
import '../widgets/track_selector.dart';
import '../models/media_models.dart';
import '../providers/auth_provider.dart';

/// Episode Detail Page — shown when viewing a specific episode.
///
/// Displays a hero image, episode metadata (SxxExx label, series name, etc.),
/// overview, cast & crew, playback technical info (video / audio / subtitle
/// streams via [MediaInfoCard] / [TechDetailCard] / [TrackSelector]), user
/// progress, and a prominent play button via [PillButton].
///
/// On desktop (≥1200px) a dual-column layout is used: content on the left,
/// a sticky control panel on the right. On mobile/tablet the original
/// single-column scrollable layout is preserved.
class EpisodeDetailScreen extends ConsumerStatefulWidget {
  final MediaItem item;

  const EpisodeDetailScreen({super.key, required this.item});

  @override
  ConsumerState<EpisodeDetailScreen> createState() =>
      _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends ConsumerState<EpisodeDetailScreen> {
  MediaStreamInfo? _streamInfo;
  bool _loadingStream = false;
  bool _overviewExpanded = false;

  // Track‑selector expansion state
  bool _audioExpanded = false;
  bool _subtitleExpanded = false;
  int _selectedAudioIndex = 0;
  int _selectedSubtitleIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlaybackInfo();
  }

  // ── Data loading ──────────────────────────────────────────────────────

  Future<void> _loadPlaybackInfo() async {
    final token = ref.read(authProvider).authResult?.token;
    final serverUrl =
        await ref.read(storageServiceProvider).getServerUrl();
    if (token == null || serverUrl == null) return;

    setState(() => _loadingStream = true);
    try {
      final userId =
          ref.read(authProvider).authResult?.user.id ?? '';
      final info = await ref.read(apiClientProvider).getPlaybackInfo(
            serverUrl: serverUrl,
            token: token,
            userId: userId,
            itemId: widget.item.id,
          );
      if (mounted) setState(() => _streamInfo = info);
    } catch (_) {
      // silently ignore
    } finally {
      if (mounted) setState(() => _loadingStream = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  MediaItem get _item => widget.item;

  List<MediaStream> get _videoStreams =>
      _streamInfo?.mediaSources
          .expand((s) => s.mediaStreams)
          .where((s) => s.isVideo)
          .toList() ??
      [];

  List<MediaStream> get _audioStreams =>
      _streamInfo?.mediaSources
          .expand((s) => s.mediaStreams)
          .where((s) => s.isAudio)
          .toList() ??
      [];

  List<MediaStream> get _subtitleStreams =>
      _streamInfo?.mediaSources
          .expand((s) => s.mediaStreams)
          .where((s) => s.isSubtitle)
          .toList() ??
      [];

  MediaSource? get _primarySource =>
      _streamInfo?.mediaSources.isNotEmpty == true
          ? _streamInfo!.mediaSources.first
          : null;

  String _formatBitrate(int bps) =>
      '${(bps / 1000000).toStringAsFixed(1)} Mbps';

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _streamTitle(MediaStream s) {
    if (s.displayTitle.isNotEmpty) return s.displayTitle;
    final parts = <String>[];
    if (s.codec.isNotEmpty) parts.add(s.codec.toUpperCase());
    if (s.resolution.isNotEmpty) parts.add(s.resolution);
    if (s.language.isNotEmpty) parts.add(s.language);
    return parts.join(' · ');
  }

  String _streamSubtitle(MediaStream s) {
    final parts = <String>[];
    if (s.bitRate > 0) parts.add(_formatBitrate(s.bitRate));
    if (s.channelLayout.isNotEmpty) parts.add(s.channelLayout);
    if (s.width > 0 && s.height > 0) parts.add('${s.width}×${s.height}');
    return parts.join(' · ');
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final token = ref.read(authProvider).authResult?.token;
    const serverUrl = 'http://localhost:19800';

    return Scaffold(
      backgroundColor: AppColors.episodeBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = AetherBreakpoints.isDesktop(context);
          if (isDesktop) {
            return _buildDesktopLayout(serverUrl, token);
          }
          return _buildMobileLayout(serverUrl, token);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Desktop dual-column layout
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDesktopLayout(String serverUrl, String? token) {
    final padding = AetherBreakpoints.pagePadding(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left column: scrollable content ─────────────────────────────
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Back button bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildDesktopContent(serverUrl, token, padding),
              ),
            ],
          ),
        ),

        // ── Right column: sticky control panel ──────────────────────────
        SizedBox(
          width: 360,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 16, padding, 16),
            child: _buildControlPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent(
      String serverUrl, String? token, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 0, padding, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 cover image
          _buildCoverImage(serverUrl, token),
          const SizedBox(height: 20),

          // Breadcrumb
          _buildBreadcrumb(),
          const SizedBox(height: 8),

          // Title section
          _buildTitleSection(),
          const SizedBox(height: 16),

          // Meta chips
          _buildMetaChips(),
          const SizedBox(height: 20),

          // Series info card
          _buildSeriesCard(),
          const SizedBox(height: 20),

          // Overview
          _buildOverviewSection(),

          // Cast & crew
          _buildCastSection(),

          // User progress
          _buildUserProgressSection(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Mobile / tablet single-column layout
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(String serverUrl, String? token) {
    return CustomScrollView(
      slivers: [
        _buildHeroAppBar(serverUrl, token),
        SliverToBoxAdapter(child: _buildMobileContent(serverUrl, token)),
      ],
    );
  }

  Widget _buildMobileContent(String serverUrl, String? token) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumb(),
          const SizedBox(height: 8),
          _buildTitleSection(),
          const SizedBox(height: 16),
          _buildMetaChips(),
          const SizedBox(height: 20),
          _buildPlayButton(),
          const SizedBox(height: 28),
          _buildSeriesCard(),
          const SizedBox(height: 20),
          _buildOverviewSection(),
          _buildCastSection(),

          // Control panel at bottom on mobile
          const SizedBox(height: 24),
          _buildControlPanel(),
          const SizedBox(height: 24),

          _buildUserProgressSection(),
        ],
      ),
    );
  }

  // ── Hero App Bar (mobile only) ────────────────────────────────────────

  Widget _buildHeroAppBar(String serverUrl, String? token) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.episodeBg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (_item.hasBackdrop || _item.hasPrimaryImage)
              Image.network(
                _item.hasBackdrop
                    ? '$serverUrl/api/images/${_item.id}/Backdrop?maxWidth=800'
                    : '$serverUrl/api/images/${_item.id}/Primary?maxWidth=600',
                fit: BoxFit.cover,
                headers: {
                  'Accept': 'image/*',
                  'X-Emby-Token': token ?? '',
                },
                errorBuilder: (_, __, ___) => _fallbackImage(),
              )
            else
              _fallbackImage(),

            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x88000000),
                    AppColors.episodeBg,
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Diamond badge — series logo at bottom-left
            Positioned(
              left: 20,
              bottom: 20,
              child: DiamondBadge(
                title: _item.seriesName.isNotEmpty
                    ? _item.seriesName
                    : _item.name,
                size: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cover Image (desktop) ────────────────────────────────────────────

  Widget _buildCoverImage(String serverUrl, String? token) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image / fallback
              if (_item.hasBackdrop || _item.hasPrimaryImage)
                Image.network(
                  _item.hasBackdrop
                      ? '$serverUrl/api/images/${_item.id}/Backdrop?maxWidth=960'
                      : '$serverUrl/api/images/${_item.id}/Primary?maxWidth=600',
                  fit: BoxFit.cover,
                  headers: {
                    'Accept': 'image/*',
                    'X-Emby-Token': token ?? '',
                  },
                  errorBuilder: (_, __, ___) => _fallbackImage(),
                )
              else
                _fallbackImage(),

              // Gradient overlay at bottom
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x66000000),
                    ],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),

              // Centered play button (visible on hover via mouse region)
              Center(
                child: _HoverPlayButton(
                  onPressed: () {
                    // TODO: launch player
                  },
                ),
              ),

              // Diamond badge
              Positioned(
                left: 16,
                bottom: 16,
                child: DiamondBadge(
                  title: _item.seriesName.isNotEmpty
                      ? _item.seriesName
                      : _item.name,
                  size: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Breadcrumb ────────────────────────────────────────────────────────

  Widget _buildBreadcrumb() {
    final parts = <String>[];
    if (_item.seriesName.isNotEmpty) parts.add(_item.seriesName);
    if (_item.parentIndexNumber > 0) {
      parts.add('S${_item.parentIndexNumber.toString().padLeft(2, '0')}');
    }
    if (_item.indexNumber > 0) {
      parts.add('E${_item.indexNumber.toString().padLeft(2, '0')}');
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            const Text(
              '·',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            parts[i],
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.episodeBg,
      child: const Center(
        child: Icon(Icons.movie_outlined,
            size: 64, color: AppColors.textSecondary),
      ),
    );
  }

  // ── Title ─────────────────────────────────────────────────────────────

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Episode name
        Text(
          _item.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        // Series name (if different from title)
        if (_item.seriesName.isNotEmpty && _item.seriesName != _item.name)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _item.seriesName,
              style: const TextStyle(
                color: AppColors.textWarmGray,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  // ── Meta Chips ────────────────────────────────────────────────────────

  Widget _buildMetaChips() {
    final chips = <Widget>[];

    if (_item.productionYear > 0) {
      chips.add(_MetaChip(label: '${_item.productionYear}'));
    }
    if (_item.communityRating > 0) {
      chips.add(_MetaChip(
        label: _item.communityRating.toStringAsFixed(1),
        icon: Icons.star_rounded,
        iconColor: AppColors.playGold,
      ));
    }
    if (_item.officialRating.isNotEmpty) {
      chips.add(_MetaChip(label: _item.officialRating));
    }
    if (_item.durationText.isNotEmpty) {
      chips.add(_MetaChip(label: _item.durationText));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  // ── Play Button (mobile) ──────────────────────────────────────────────

  Widget _buildPlayButton() {
    final progress = _item.userData?.progressPercent ?? 0;
    final playLabel = progress > 0 ? '继续播放' : '播放';

    return PillButton(
      icon: Icons.play_arrow_rounded,
      label: playLabel,
      backgroundColor: AppColors.playGold,
      textColor: AppColors.textPrimary,
      onPressed: () {
        // TODO: launch player
      },
      onMenuPressed: () => _showMoreOptions(),
    );
  }

  // ── Series Info Card ──────────────────────────────────────────────────

  Widget _buildSeriesCard() {
    if (_item.seriesName.isEmpty) return const SizedBox.shrink();

    const serverUrl = 'http://localhost:19800';
    final token = ref.read(authProvider).authResult?.token;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Series thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: _item.hasPrimaryImage
                  ? Image.network(
                      '$serverUrl/api/images/${_item.id}/Primary?maxWidth=128',
                      fit: BoxFit.cover,
                      headers: {
                        'Accept': 'image/*',
                        'X-Emby-Token': token ?? '',
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.chipBg,
                        child: const Icon(Icons.tv,
                            color: AppColors.textSecondary, size: 28),
                      ),
                    )
                  : Container(
                      color: AppColors.chipBg,
                      child: const Icon(Icons.tv,
                          color: AppColors.textSecondary, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '所属剧集',
                  style: TextStyle(
                    color: AppColors.textWarmGray,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _item.seriesName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_item.episodeLabel.isNotEmpty)
                  Text(
                    _item.episodeLabel,
                    style: const TextStyle(
                      color: AppColors.textWarmGray,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ── Overview ──────────────────────────────────────────────────────────

  Widget _buildOverviewSection() {
    if (_item.overview.isEmpty) return const SizedBox.shrink();

    const maxChars = 200;
    final needsTruncation = _item.overview.length > maxChars;
    final displayText =
        needsTruncation && !_overviewExpanded
            ? '${_item.overview.substring(0, maxChars)}…'
            : _item.overview;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '简介',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: const TextStyle(
              color: AppColors.textWarmGray,
              fontSize: 14,
              height: 1.65,
            ),
          ),
          if (needsTruncation)
            GestureDetector(
              onTap: () =>
                  setState(() => _overviewExpanded = !_overviewExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _overviewExpanded ? '收起' : '展开全部',
                  style: const TextStyle(
                    color: AppColors.playGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Cast & Crew ───────────────────────────────────────────────────────

  Widget _buildCastSection() {
    final actors = _item.actors;
    final directors = _item.directors;
    final writers = _item.writers;

    if (actors.isEmpty && directors.isEmpty && writers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '演职人员',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal scrolling cast list
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actors.length + directors.length + writers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final person = _allPeople[index];
                return _CastCard(
                  person: person,
                  serverUrl: 'http://localhost:19800',
                  token:
                      ref.read(authProvider).authResult?.token,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Person> get _allPeople => [
        ..._item.directors,
        ..._item.writers,
        ..._item.actors,
      ];

  // ── Control Panel ─────────────────────────────────────────────────────

  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.nebulaDark,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 媒体源 (Media Source) ─────────────────────────────────────
          _buildPanelSectionLabel('媒体源'),
          const SizedBox(height: 8),
          _buildMediaSourceDropdown(),
          const SizedBox(height: 18),

          // ── 音频 (Audio) ──────────────────────────────────────────────
          _buildPanelSectionLabel('音频'),
          const SizedBox(height: 8),
          _buildAudioDropdown(),
          const SizedBox(height: 18),

          // ── 字幕 (Subtitle) ──────────────────────────────────────────
          _buildPanelSectionLabel('字幕'),
          const SizedBox(height: 8),
          _buildSubtitleDropdown(),
          const SizedBox(height: 22),

          // ── 播放 Button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.celestialCyan,
                foregroundColor: AppColors.deepVoid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // TODO: launch player
              },
              child: const Text(
                '播放',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Media Source Dropdown ─────────────────────────────────────────────

  Widget _buildMediaSourceDropdown() {
    if (_loadingStream) {
      return const _PanelDropdownPlaceholder(text: '加载中…');
    }

    final sources = _streamInfo?.mediaSources ?? [];
    if (sources.isEmpty) {
      return const _PanelDropdownPlaceholder(text: '无可用媒体源');
    }

    final currentSource = sources.first;
    final displayText = currentSource.name.isNotEmpty
        ? currentSource.name
        : '未知';

    return _PanelDropdown(
      displayText: displayText,
      onTap: () => _showMediaSourceMenu(sources),
    );
  }

  void _showMediaSourceMenu(List<MediaSource> sources) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < sources.length; i++)
                ListTile(
                  leading: Icon(
                    i == 0 ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: i == 0 ? AppColors.celestialCyan : AppColors.textTertiary,
                    size: 20,
                  ),
                  title: Text(
                    sources[i].name.isNotEmpty ? sources[i].name : '源 ${i + 1}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  subtitle: sources[i].container.isNotEmpty
                      ? Text(
                          sources[i].container.toUpperCase(),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        )
                      : null,
                  onTap: () => Navigator.pop(context),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Audio Dropdown ────────────────────────────────────────────────────

  Widget _buildAudioDropdown() {
    if (_loadingStream) {
      return const _PanelDropdownPlaceholder(text: '加载中…');
    }

    if (_audioStreams.isEmpty) {
      return const _PanelDropdownPlaceholder(text: '无可用音频');
    }

    final idx = _selectedAudioIndex.clamp(0, _audioStreams.length - 1);
    return _PanelDropdown(
      displayText: _streamTitle(_audioStreams[idx]),
      onTap: () => _showAudioMenu(),
    );
  }

  void _showAudioMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < _audioStreams.length; i++)
                ListTile(
                  leading: Icon(
                    i == _selectedAudioIndex
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: i == _selectedAudioIndex
                        ? AppColors.celestialCyan
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  title: Text(
                    _streamTitle(_audioStreams[i]),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    _streamSubtitle(_audioStreams[i]),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                  onTap: () {
                    setState(() => _selectedAudioIndex = i);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Subtitle Dropdown ────────────────────────────────────────────────

  Widget _buildSubtitleDropdown() {
    if (_loadingStream) {
      return const _PanelDropdownPlaceholder(text: '加载中…');
    }

    if (_subtitleStreams.isEmpty) {
      return const _PanelDropdownPlaceholder(text: '无可用字幕');
    }

    final idx = _selectedSubtitleIndex.clamp(0, _subtitleStreams.length - 1);
    return _PanelDropdown(
      displayText: _streamTitle(_subtitleStreams[idx]),
      onTap: () => _showSubtitleMenu(),
    );
  }

  void _showSubtitleMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nebulaDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < _subtitleStreams.length; i++)
                ListTile(
                  leading: Icon(
                    i == _selectedSubtitleIndex
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: i == _selectedSubtitleIndex
                        ? AppColors.celestialCyan
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  title: Text(
                    _streamTitle(_subtitleStreams[i]),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    _streamSubtitle(_subtitleStreams[i]),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                  onTap: () {
                    setState(() => _selectedSubtitleIndex = i);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── User Progress ─────────────────────────────────────────────────────

  Widget _buildUserProgressSection() {
    final userData = _item.userData;
    if (userData == null || userData.playCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              userData.played
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_rounded,
              size: 24,
              color: userData.played
                  ? Colors.green.shade400
                  : AppColors.playGold,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData.played ? '已观看' : '已观看 ${userData.playCount} 次',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (userData.progressPercent > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: userData.progressPercent,
                        backgroundColor: AppColors.chipBg,
                        color: AppColors.playGold,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(userData.progressPercent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.textWarmGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── More options sheet ────────────────────────────────────────────────

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.episodeBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _BottomSheetItem(
                icon: Icons.info_outline_rounded,
                label: '媒体详情',
                onTap: () {
                  Navigator.pop(context);
                  _showMediaDetailDialog();
                },
              ),
              _BottomSheetItem(
                icon: Icons.share_rounded,
                label: '分享',
                onTap: () => Navigator.pop(context),
              ),
              _BottomSheetItem(
                icon: Icons.favorite_border_rounded,
                label: '添加到收藏',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showMediaDetailDialog() {
    final providerIds = _item.providerIds;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.episodeBg,
          title: const Text(
            '媒体详情',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('ID', _item.id),
                _detailRow('类型', _item.type),
                if (_item.productionYear > 0)
                  _detailRow('年份', '${_item.productionYear}'),
                if (_item.runTimeTicks > 0)
                  _detailRow('时长', _item.durationFormatted),
                if (providerIds.containsKey('Imdb'))
                  _detailRow('IMDB', providerIds['Imdb']!),
                if (providerIds.containsKey('Tmdb'))
                  _detailRow('TMDB', providerIds['Tmdb']!),
                if (providerIds.containsKey('Tvdb'))
                  _detailRow('TVDB', providerIds['Tvdb']!),
                if (_primarySource != null) ...[
                  const Divider(color: AppColors.borderSubtle),
                  _detailRow('容器', _primarySource!.container.toUpperCase()),
                  if (_primarySource!.size > 0)
                    _detailRow('文件大小', _formatSize(_primarySource!.size)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭',
                  style: TextStyle(color: AppColors.playGold)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textWarmGray,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Hover‑aware play button that shows a 60px circle on hover.
class _HoverPlayButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _HoverPlayButton({required this.onPressed});

  @override
  State<_HoverPlayButton> createState() => _HoverPlayButtonState();
}

class _HoverPlayButtonState extends State<_HoverPlayButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.celestialCyan.withValues(
              alpha: _hovered ? 0.95 : 0.3,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.celestialCyan.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 32,
            color: _hovered ? AppColors.deepVoid : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Panel dropdown trigger that shows the current selection and opens a menu.
class _PanelDropdown extends StatelessWidget {
  final String displayText;
  final VoidCallback onTap;

  const _PanelDropdown({
    required this.displayText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.chipBg,
            border: Border.all(color: AppColors.borderSubtle, width: 0.5),
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for dropdowns while loading or when empty.
class _PanelDropdownPlaceholder extends StatelessWidget {
  final String text;

  const _PanelDropdownPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Small meta chip (year, rating, duration, etc.)
class _MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _MetaChip({required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? AppColors.textPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cast / crew avatar card for horizontal scrolling list
class _CastCard extends StatelessWidget {
  final Person person;
  final String serverUrl;
  final String? token;

  const _CastCard({
    required this.person,
    required this.serverUrl,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = person.hasImage
        ? '$serverUrl/api/images/${person.id}/Primary?maxWidth=120'
        : null;

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.chipBg,
            backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl) : null,
            onBackgroundImageError: imageUrl != null ? (_, __) {} : null,
            child: imageUrl == null
                ? const Icon(Icons.person,
                    color: AppColors.textSecondary, size: 28)
                : null,
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            person.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          // Role
          if (person.role != null && person.role!.isNotEmpty)
            Text(
              person.role!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textWarmGray,
                fontSize: 9,
              ),
            ),
          // Type badge
          Text(
            person.type,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textWarmGray,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet menu item
class _BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomSheetItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
