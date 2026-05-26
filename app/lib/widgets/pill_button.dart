import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 全宽胶囊形播放按钮
class PillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool showMenuIcon;
  final VoidCallback? onMenuPressed;

  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.textColor = AppColors.deepVoid,
    this.onPressed,
    this.showMenuIcon = true,
    this.onMenuPressed,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() {
              _isHovered = false;
              _isPressed = false;
            }),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: 54,
                transform: _isPressed
                    ? (Matrix4.identity()..scaleByDouble(0.98, 0.98, 1.0, 1.0))
                    : (_isHovered
                        ? (Matrix4.identity()..scaleByDouble(1.02, 1.02, 1.0, 1.0))
                        : Matrix4.identity()),
                decoration: BoxDecoration(
                  gradient: widget.backgroundColor != null
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.celestialCyan, AppColors.novaPurple],
                        ),
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(AppColors.radiusXl),
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: AppColors.celestialCyan.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      )
                    else
                      BoxShadow(
                        color: (widget.backgroundColor ?? AppColors.celestialCyan)
                            .withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: widget.textColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showMenuIcon) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: widget.onMenuPressed,
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
