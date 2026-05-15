import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 分类标签组件 V2
///
/// 支持多种变体：
/// - genre: 圆角胶囊（类型标签）
/// - filter: 可选中过滤器
/// - accent: 强调色标签
class AetherChip extends StatelessWidget {
  final String label;
  final AetherChipVariant variant;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const AetherChip({
    super.key,
    required this.label,
    this.variant = AetherChipVariant.genre,
    this.selected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  /// 类型标签（不可选中）
  const AetherChip.genre({
    super.key,
    required this.label,
    this.icon,
    this.color,
  })  : variant = AetherChipVariant.genre,
        selected = false,
        onTap = null;

  /// 可选中过滤器
  const AetherChip.filter({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
  })  : variant = AetherChipVariant.filter,
        color = null;

  /// 强调色标签
  const AetherChip.accent({
    super.key,
    required this.label,
    this.icon,
  })  : variant = AetherChipVariant.accent,
        selected = false,
        onTap = null,
        color = null;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AetherChipVariant.genre:
        return _buildGenre();
      case AetherChipVariant.filter:
        return _buildFilter();
      case AetherChipVariant.accent:
        return _buildAccent();
    }
  }

  Widget _buildGenre() {
    final c = color ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.celestialCyan.withValues(alpha: 0.12)
              : AppColors.chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.celestialCyan.withValues(alpha: 0.4)
                : AppColors.borderSubtle,
            width: selected ? 1.0 : 0.5,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.celestialCyan.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected
                    ? AppColors.celestialCyan
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.celestialCyan
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.deepVoid),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.deepVoid,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

enum AetherChipVariant { genre, filter, accent }
