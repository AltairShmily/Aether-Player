import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 剧集卡片 - 用于横向滚动列表（继续观看）
class EpisodeCard extends StatefulWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final double? progress;
  final VoidCallback? onTap;
  final String? token;
  final String? serverUrl;
  const EpisodeCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.progress,
    this.onTap,
    this.token,
    this.serverUrl,
  });

  @override
  State<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? (Matrix4.identity()..translateByDouble(0.0, -4.0, 0.0, 1.0))
              : Matrix4.identity(),
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: AppColors.celestialCyan.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 160,
                        height: 90,
                        color: AppColors.nebulaDark,
                        child: widget.imageUrl != null
                            ? Image.network(
                                widget.imageUrl!,
                                fit: BoxFit.cover,
                                headers: widget.token != null
                                    ? {
                                        'X-Emby-Token': widget.token!,
                                        'X-Emby-Server': widget.serverUrl ?? '',
                                      }
                                    : null,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      // hover 播放按钮覆盖
                      AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Positioned.fill(
                          child: Container(
                            color: AppColors.deepVoid.withValues(alpha: 0.35),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                color: AppColors.celestialCyan,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 进度条
                      if (widget.progress != null && widget.progress! > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: widget.progress,
                            backgroundColor: Colors.black45,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.auroraGreen,
                            ),
                            minHeight: 3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 标题
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.play_circle_outline,
        size: 28,
        color: AppColors.textSecondary,
      ),
    );
  }
}
