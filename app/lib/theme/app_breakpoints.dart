import 'package:flutter/material.dart';

/// Aether Player 响应式断点系统
///
/// 统一管理所有屏幕尺寸断点，确保跨设备一致性。
class AetherBreakpoints {
  AetherBreakpoints._();

  // ══════════════════════════════════════════════════
  //  断点值 (px)
  // ══════════════════════════════════════════════════
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wide = 1440;

  // ══════════════════════════════════════════════════
  //  判断方法
  // ══════════════════════════════════════════════════

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  // ══════════════════════════════════════════════════
  //  网格列数
  // ══════════════════════════════════════════════════

  /// 根据屏幕宽度返回推荐的网格列数
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobile) return 2;
    if (w < tablet) return 3;
    if (w < desktop) return 4;
    if (w < wide) return 5;
    return 6;
  }

  // ══════════════════════════════════════════════════
  //  内边距
  // ══════════════════════════════════════════════════

  /// 页面水平内边距
  static double pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobile) return 16;
    if (w < tablet) return 24;
    if (w < desktop) return 32;
    return 48;
  }

  /// 卡片间距
  static double cardSpacing(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobile) return 10;
    if (w < tablet) return 14;
    return 16;
  }

  // ══════════════════════════════════════════════════
  //  布局模式
  // ══════════════════════════════════════════════════

  /// 是否使用底部导航栏 (而非侧边 Rail)
  static bool useBottomNav(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  /// Hero Banner 高度
  static double heroHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobile) return 200;
    if (w < tablet) return 280;
    return 360;
  }

  /// 卡片宽高比
  static double cardAspectRatio(BuildContext context, {bool square = false}) {
    if (square) return 1.0;
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobile) return 2 / 3; // 竖版海报
    return 3 / 4;
  }
}
