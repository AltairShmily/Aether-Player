import 'package:flutter/material.dart';
import '../models/media_models.dart';
import '../theme/app_colors.dart';
import 'aether_progress.dart';
import 'rating_badge.dart';

/// ---------------------------------------------------------------------------
/// MediaCard — Premium media card with Celestial Glow hover effects.
///
/// On desktop: hover triggers translateY(-6px) lift, scale(1.03), and a cyan
/// glow shadow. A play-button overlay fades in over the poster.
/// On mobile: tap works as usual with no hover decoration.
///
/// **调用契约**：[imageHeaders] 必须在首次渲染时就已就绪。
/// `NetworkImage` 的相等性只比较 url 与 scale、**不含 headers**，
/// 因此若首帧用空头发起请求（会被本地代理拒绝为 502），
/// 事后补上 headers 也不会触发重新解析，图片将永久停留在失败态。
/// 需要异步读取服务器地址的页面，应在地址就绪前不渲染本组件。
/// ---------------------------------------------------------------------------
class MediaCard extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final String Function(String, {String type, int? maxWidth}) imageUrlBuilder;

  /// 本地代理转发所需的头（X-Emby-Server / X-Emby-Token）。
  /// 缺失时图片请求会被代理拒绝（502），海报无法显示。
  final Map<String, String> imageHeaders;

  /// 播放进度（0–1），非空时在海报底部显示进度条，用于「继续观看」卡片
  final double? progress;

  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.imageUrlBuilder,
    this.imageHeaders = const {},
    this.progress,
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
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            boxShadow: [
              if (_isHovered) ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.celestialCyan.withValues(alpha: 0.15),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.celestialCyan.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
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
                      headers: widget.imageHeaders,
                      progress: widget.progress,
                    ),
                  ),

                  // ── Title ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    // 宽度跟随卡片：写死数值会在自适应网格下截断或留白
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10.9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // ── Year / Rating / Duration meta row ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 2, 8),
                    child: Row(
                      children: [
                        if (item.productionYear > 0)
                          Text(
                            '${item.productionYear}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              fontFamily: 'DM Mono',
                            ),
                          ),
                        if (item.communityRating > 0) ...[
                          if (item.productionYear > 0) const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.supernova),
                          const SizedBox(width: 2),
                          Text(
                            item.communityRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontFamily: 'DM Mono',
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

  /// 代理转发所需的头；与 Accept 合并后一并发送
  final Map<String, String> headers;

  /// 播放进度（0–1），非空时在海报底部显示进度条
  final double? progress;

  const _PosterSection({
    required this.imageUrl,
    required this.item,
    required this.isHovered,
    this.headers = const {},
    this.progress,
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
                      // X-Emby-Server / X-Emby-Token 由调用方注入，
                      // 缺失时本地代理无法定位上游而返回 502
                      headers: {'Accept': 'image/*', ...headers},
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      // 参数名避开字段 progress：此处是图片下载事件，非播放进度
                      loadingBuilder: (_, child, chunk) {
                        if (chunk == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: chunk.expectedTotalBytes != null
                                ? chunk.cumulativeBytesLoaded /
                                    chunk.expectedTotalBytes!
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
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC0A0E14), Colors.transparent],
                  stops: [0.0, 0.6],
                ),
              ),
            ),

            // ── 右上角评分角标（仅有评分时出现）──
            Positioned(
              top: 8,
              right: 8,
              child: RatingBadge(rating: item.communityRating),
            ),

            // ── 底部播放进度条（仅「继续观看」等有进度时出现）──
            if (progress != null && progress! > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AetherProgress.mini(value: progress!.clamp(0.0, 1.0)),
              ),

            // ── Poster inner title (bottom overlay) ──
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xE6F0F4F8), // rgba(240,244,248,0.9)
                  fontSize: 9.8,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),

            // ── Play button overlay (fades in on hover) ──
            AnimatedOpacity(
              opacity: isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Container(
                color: AppColors.deepVoid.withValues(alpha: 0.35),
                child: Center(
                  child: AnimatedScale(
                    scale: isHovered ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.elasticOut,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.celestialCyan.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.celestialCyan.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 20,
                        color: AppColors.deepVoid,
                      ),
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

  /// 本地代理转发所需的头（X-Emby-Server / X-Emby-Token）。
  /// 缺失时图片请求会被代理拒绝（502）；且须在首次渲染时就绪，
  /// 因 `NetworkImage` 的相等性不含 headers，事后补头不会触发重新解析。
  final Map<String, String> imageHeaders;

  const SearchHintCard({
    super.key,
    required this.hint,
    required this.onTap,
    required this.imageUrlBuilder,
    this.imageHeaders = const {},
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
                  headers: {'Accept': 'image/*', ...imageHeaders},
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
                Icon(Icons.star_rounded, size: 16, color: AppColors.supernova),
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
        return '单集';
      case 'Audio':
        return '音乐';
      case 'MusicAlbum':
        return '专辑';
      case 'Person':
        return '人物';
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
