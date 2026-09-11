import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 海报右上角的评分角标。
///
/// 抽为独立原子组件，供各处海报卡复用 —— 此前 8 个 screen 各自内联海报卡，
/// 评分信息有的放在卡片下方 meta 行、有的完全没有，网格视图下尤其难以扫读。
///
/// 评分无效（<= 0）时返回 [SizedBox.shrink]，不占位也不留空框。
class RatingBadge extends StatelessWidget {
  /// 评分值，通常为 Emby 的 CommunityRating（0–10）
  final double rating;

  /// 小数位数，默认 1 位（如 8.7）
  final int decimals;

  const RatingBadge({
    super.key,
    required this.rating,
    this.decimals = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        // 半透明深底 + 细描边，保证在任意海报上都可读
        color: AppColors.deepVoid.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppColors.radiusXs),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 11,
            color: AppColors.ratingStar,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(decimals),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'DM Mono',
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
