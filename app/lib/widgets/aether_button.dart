import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 发光按钮组件
///
/// 三种变体：
/// - primary: 渐变填充 + 悬停发光
/// - secondary: 半透明 + 边框
/// - ghost: 透明 + 强调色边框
class AetherButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AetherButtonVariant variant;
  final double? width;
  final bool compact;

  const AetherButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AetherButtonVariant.primary,
    this.width,
    this.compact = false,
  });

  /// 主要操作按钮 (渐变 + 发光)
  const AetherButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.compact = false,
  }) : variant = AetherButtonVariant.primary;

  /// 次要操作按钮 (半透明)
  const AetherButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.compact = false,
  }) : variant = AetherButtonVariant.secondary;

  /// 幽灵按钮 (透明 + 边框)
  const AetherButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.compact = false,
  }) : variant = AetherButtonVariant.ghost;

  @override
  State<AetherButton> createState() => _AetherButtonState();
}

enum AetherButtonVariant { primary, secondary, ghost }

class _AetherButtonState extends State<AetherButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.variant == AetherButtonVariant.primary && widget.onPressed != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AetherButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant == AetherButtonVariant.primary && widget.onPressed != null) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0);

            return AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width,
                padding: pad,
                decoration: _buildDecoration(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: widget.compact ? 16 : 18,
                        color: _textColor(),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: widget.compact ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: _textColor(),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    switch (widget.variant) {
      case AetherButtonVariant.primary:
        return BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: AppColors.celestialCyan
                    .withValues(alpha: 0.3 * _pulseAnimation.value),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: AppColors.celestialCyan.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        );

      case AetherButtonVariant.secondary:
        return BoxDecoration(
          color: AppColors.stardust,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppColors.celestialCyan.withValues(alpha: 0.2)
                : AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: AppColors.celestialCyan.withValues(alpha: 0.06),
                blurRadius: 16,
              ),
          ],
        );

      case AetherButtonVariant.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppColors.celestialCyan.withValues(alpha: 0.5)
                : AppColors.celestialCyan.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: AppColors.celestialCyan.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
          ],
        );
    }
  }

  Color _textColor() {
    switch (widget.variant) {
      case AetherButtonVariant.primary:
        return AppColors.deepVoid;
      case AetherButtonVariant.secondary:
        return AppColors.textPrimary;
      case AetherButtonVariant.ghost:
        return AppColors.celestialCyan;
    }
  }
}
