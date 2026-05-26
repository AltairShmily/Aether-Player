import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 菱形 Logo 徽章 - 悬浮在 Hero 图片与内容交界处
class DiamondBadge extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double size;

  const DiamondBadge({
    super.key,
    required this.title,
    this.subtitle,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.deepVoid,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(AppColors.radiusXs),
        border: Border.all(
          color: AppColors.celestialCyan.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.celestialCyan.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
