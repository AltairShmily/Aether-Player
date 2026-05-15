import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 剧集卡片 - 用于横向滚动列表（继续观看）
class EpisodeCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    width: 160,
                    height: 90,
                    color: AppColors.cardBg,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            headers: token != null
                                ? {'X-Emby-Token': token!, 'X-Emby-Server': serverUrl ?? ''}
                                : null,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  // 进度条
                  if (progress != null && progress! > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.black45,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.playMint,
                        ),
                        minHeight: 3,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // 标题
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textWarmGray,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.play_circle_outline, size: 28, color: AppColors.textSecondary),
    );
  }
}
