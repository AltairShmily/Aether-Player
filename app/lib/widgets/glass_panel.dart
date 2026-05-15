import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 毛玻璃面板组件
///
/// 比 AetherCard 更轻量的容器，适用于浮层、底部弹窗、导航栏等。
/// 核心特征：半透明背景 + 背景模糊 + 微光边框。
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color backgroundColor;
  final bool showBorder;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 16,
    this.backgroundColor = const Color(0x0DFFFFFF), // 5% white
    this.showBorder = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  /// 底部播放栏样式
  const GlassPanel.nowPlaying({
    super.key,
    required this.child,
  })  : borderRadius = 0,
        blurSigma = 20,
        backgroundColor = const Color(0xCC0A0E14), // 80% deepVoid
        showBorder = true,
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin = null,
        width = null,
        height = null;

  /// 导航栏样式
  const GlassPanel.navBar({
    super.key,
    required this.child,
  })  : borderRadius = 0,
        blurSigma = 24,
        backgroundColor = const Color(0xCC111820), // 80% nebulaDark
        showBorder = true,
        padding = null,
        margin = null,
        width = null,
        height = null;

  /// 顶部 OSD 栏样式
  const GlassPanel.osdTop({
    super.key,
    required this.child,
  })  : borderRadius = 0,
        blurSigma = 12,
        backgroundColor = Colors.transparent,
        showBorder = false,
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin = null,
        width = null,
        height = null;

  /// 浮动工具面板
  const GlassPanel.floating({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  })  : borderRadius = 16,
        blurSigma = 20,
        backgroundColor = const Color(0x14FFFFFF), // 8% white
        showBorder = true,
        width = null,
        height = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: AppColors.borderSubtle,
                width: 0.5,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            padding: padding,
            color: backgroundColor,
            child: child,
          ),
        ),
      ),
    );
  }
}
