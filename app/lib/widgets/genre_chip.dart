import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 类型标签芯片
class GenreChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const GenreChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
