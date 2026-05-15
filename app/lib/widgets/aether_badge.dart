import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 徽章组件 V2
///
/// 支持多种变体：
/// - diamond: 菱形旋转徽章（Logo/评分）
/// - pill: 胶囊徽章（状态/标签）
/// - dot: 圆点徽章（在线/通知）
/// - rating: 评分徽章（星级+数字）
class AetherBadge extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final AetherBadgeVariant variant;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final bool glowing;

  const AetherBadge({
    super.key,
    this.label,
    this.icon,
    this.variant = AetherBadgeVariant.pill,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.glowing = false,
  });

  /// 菱形 Logo 徽章
  const AetherBadge.diamond({
    super.key,
    required this.label,
    this.size = 56,
    this.color = AppColors.celestialCyan,
    this.glowing = true,
  })  : icon = null,
        variant = AetherBadgeVariant.diamond,
        backgroundColor = null;

  /// 胶囊状态徽章
  const AetherBadge.pill({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.glowing = false,
  })  : icon = null,
        variant = AetherBadgeVariant.pill,
        size = 24;

  /// 圆点在线徽章
  const AetherBadge.dot({
    super.key,
    this.color = AppColors.auroraGreen,
    this.size = 10,
    this.glowing = true,
  })  : label = null,
        icon = null,
        variant = AetherBadgeVariant.dot,
        backgroundColor = null;

  /// 评分徽章
  AetherBadge.rating({
    super.key,
    required double score,
    this.size = 36,
    this.color = AppColors.supernova,
    this.glowing = false,
  })  : label = score.toStringAsFixed(1),
        icon = Icons.star_rounded,
        variant = AetherBadgeVariant.rating,
        backgroundColor = null;

  /// 角标计数
  AetherBadge.count({
    super.key,
    required int count,
    this.size = 20,
    this.color = AppColors.plasmaPink,
    this.glowing = false,
  })  : label = count > 99 ? '99+' : '$count',
        icon = null,
        variant = AetherBadgeVariant.count,
        backgroundColor = null;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AetherBadgeVariant.diamond:
        return _buildDiamond();
      case AetherBadgeVariant.pill:
        return _buildPill();
      case AetherBadgeVariant.dot:
        return _buildDot();
      case AetherBadgeVariant.rating:
        return _buildRating();
      case AetherBadgeVariant.count:
        return _buildCount();
    }
  }

  Widget _buildDiamond() {
    final c = color ?? AppColors.celestialCyan;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xCC0A0E14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          if (glowing)
            BoxShadow(
              color: c.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: c,
            fontSize: size * 0.16,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPill() {
    final c = color ?? AppColors.textPrimary;
    final bg = backgroundColor ?? AppColors.chipBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: Text(
        label ?? '',
        style: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDot() {
    final c = color ?? AppColors.auroraGreen;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        boxShadow: [
          if (glowing)
            BoxShadow(
              color: c.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }

  Widget _buildRating() {
    final c = color ?? AppColors.supernova;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            label ?? '',
            style: TextStyle(
              color: c,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCount() {
    final c = color ?? AppColors.plasmaPink;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
      ),
      child: Text(
        label ?? '',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum AetherBadgeVariant { diamond, pill, dot, rating, count }
