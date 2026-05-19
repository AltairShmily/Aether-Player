import 'package:flutter/material.dart';
import '../models/media_models.dart';
import '../theme/app_colors.dart';

/// ---------------------------------------------------------------------------
/// MediaCard — Premium media card with Celestial Glow hover effects.
///
/// On desktop: hover triggers translateY(-6px) lift, scale(1.03), and a cyan
/// glow shadow. A play-button overlay fades in over the poster.
/// On mobile: tap works as usual with no hover decoration.
/// ---------------------------------------------------------------------------
class MediaCard extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final String Function(String, {String type, int? maxWidth}) imageUrlBuilder;

  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.imageUrlBuilder,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imageUrl = widget.imageUrlBuilder(
      item.id,
      type: 'Primary',
      maxWidth: 300,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            boxShadow: [
              if (_isHovered) AppColors.glowCyan(blur: 18, spread: 1),
            ],
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            color: AppColors.nebulaDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              side: BorderSide(
                color: _isHovered
                    ? AppColors.celestialCyan.withValues(alpha: 0.35)
                    : AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Poster (2:3 ratio) + gradient + play overlay ──
                  Expanded(
                    child: _PosterSection(
                      imageUrl: imageUrl,
                      item: item,
                      isHovered: _isHovered,
                    ),
                  ),

                  // ── Title ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // ── Year / Rating / Duration meta row ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Row(
                      children: [
                        if (item.productionYear > 0)
                          Text(
                            '${item.productionYear}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        if (item.communityRating > 0) ...[
                          if (item.productionYear > 0) const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              size: 13, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            item.communityRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (item.durationText.isNotEmpty)
                          Text(
                            item.durationText,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _PosterSection — Poster image with gradient overlay & play button
// ═══════════════════════════════════════════════════════════════════════════

class _PosterSection extends StatelessWidget {
  final String imageUrl;
  final MediaItem item;
  final bool isHovered;

  const _PosterSection({
    required this.imageUrl,
    required this.item,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppColors.radiusMd),
      ),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Poster image / placeholder ──
            Container(
              width: double.infinity,
              color: AppColors.stardust,
              child: item.hasPrimaryImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      headers: const {'Accept': 'image/*'},
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                            color: AppColors.celestialCyan,
                          ),
                        );
                      },
                    )
                  : _buildPlaceholder(),
            ),

            // ── Bottom gradient for text readability ──
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0A0E14)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),

            // ── Play button overlay (fades in on hover) ──
            AnimatedOpacity(
              opacity: isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Container(
                color: AppColors.deepVoid.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.celestialCyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.celestialCyan.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 28,
                      color: AppColors.deepVoid,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        item.type == 'Movie'
            ? Icons.movie_outlined
            : item.type == 'Series'
                ? Icons.tv_outlined
                : item.type == 'Audio'
                    ? Icons.music_note_outlined
                    : Icons.video_file_outlined,
        size: 40,
        color: AppColors.textTertiary,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SearchHintCard — Unchanged from original.
// ═══════════════════════════════════════════════════════════════════════════

class SearchHintCard extends StatelessWidget {
  final SearchHint hint;
  final VoidCallback onTap;
  final String Function(String, {String type, int? maxWidth}) imageUrlBuilder;

  const SearchHintCard({
    super.key,
    required this.hint,
    required this.onTap,
    required this.imageUrlBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = imageUrlBuilder(hint.id, type: 'Primary', maxWidth: 200);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: hint.hasImage
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  headers: const {'Accept': 'image/*'},
                  errorBuilder: (_, __, ___) => _buildSmallPlaceholder(theme),
                )
              : _buildSmallPlaceholder(theme),
        ),
      ),
      title: Text(
        hint.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _typeLabel(hint.type),
          if (hint.productionYear > 0) '${hint.productionYear}',
        ].where((s) => s.isNotEmpty).join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: hint.communityRating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
                const SizedBox(width: 2),
                Text(
                  hint.communityRating.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            )
          : null,
      onTap: onTap,
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'Movie':
        return '电影';
      case 'Series':
        return '剧集';
      case 'Episode':
        return '剧集';
      case 'Audio':
        return '音乐';
      case 'MusicAlbum':
        return '专辑';
      default:
        return type;
    }
  }

  Widget _buildSmallPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
