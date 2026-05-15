import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 毛玻璃卡片组件
///
/// 核心设计元素：半透明背景 + 模糊滤镜 + 悬停发光边框。
/// 支持 V1 兼容模式（不使用模糊）以覆盖低端设备。
class AetherCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// 是否启用毛玻璃效果（默认 true，低端设备可关闭）
  final bool enableBlur;

  /// 自定义背景色（默认使用半透明白色）
  final Color? backgroundColor;

  /// 悬停时的发光色
  final Color glowColor;

  /// 圆角半径
  final double borderRadius;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  const AetherCard({
    super.key,
    required this.child,
    this.onTap,
    this.enableBlur = true,
    this.backgroundColor,
    this.glowColor = AppColors.celestialCyan,
    this.borderRadius = 16,
    this.padding,
    this.margin,
  });

  /// 简洁的卡片构造（无模糊）
  const AetherCard.simple({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor = AppColors.celestialCyan,
    this.borderRadius = 16,
    this.padding,
    this.margin,
  })  : enableBlur = false,
        backgroundColor = null;

  @override
  State<AetherCard> createState() => _AetherCardState();
}

class _AetherCardState extends State<AetherCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _glowController.forward();
    } else {
      _glowController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ??
        const Color(0x0DFFFFFF); // rgba(255,255,255,0.05)

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Color.lerp(
                    AppColors.borderSubtle,
                    widget.glowColor.withValues(alpha: 0.3),
                    _glowAnimation.value,
                  )!,
                  width: _isHovered ? 1.0 : 0.5,
                ),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: widget.glowColor
                          .withValues(alpha: 0.12 * _glowAnimation.value),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: BackdropFilter(
                  enabled: widget.enableBlur,
                  filter: ImageFilter.blur(
                    sigmaX: widget.enableBlur ? 12 : 0,
                    sigmaY: widget.enableBlur ? 12 : 0,
                  ),
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: bgColor,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
