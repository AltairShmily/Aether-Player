import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable metadata chip for displaying tags like year, rating, duration, etc.
///
/// Used across detail screens (Series, Media, Episode) to avoid duplication.
class MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final BorderSide? border;
  final EdgeInsetsGeometry padding;

  const MetaChip({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.textStyle,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveStyle = textStyle ??
        theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(8),
        border: border != null ? Border.fromBorderSide(border!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(label, style: effectiveStyle),
        ],
      ),
    );
  }
}
