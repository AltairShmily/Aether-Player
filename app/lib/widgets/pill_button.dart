import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 全宽胶囊形播放按钮
class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool showMenuIcon;
  final VoidCallback? onMenuPressed;

  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor = AppColors.playGold,
    this.textColor = AppColors.textPrimary,
    this.onPressed,
    this.showMenuIcon = true,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 54,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showMenuIcon) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
