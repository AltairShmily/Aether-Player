import 'package:flutter/material.dart';

/// Aether 页面转场动效
///
/// 提供统一的页面切换动画，替代默认的 MaterialPageRoute。
/// 包含三种模式：
/// - fadeSlide: 淡入 + 轻微上滑（推荐用于大部分页面）
/// - fadeScale: 淡入 + 缩放（用于弹出/详情页）
/// - slideFromRight: 从右侧滑入（用于层级导航）
class AetherPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AetherTransitionType type;

  AetherPageRoute({
    required this.page,
    this.type = AetherTransitionType.fadeSlide,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            switch (type) {
              case AetherTransitionType.fadeSlide:
                return _buildFadeSlide(curved, child);
              case AetherTransitionType.fadeScale:
                return _buildFadeScale(curved, child);
              case AetherTransitionType.slideFromRight:
                return _buildSlideFromRight(curved, child);
            }
          },
        );

  /// 淡入 + 轻微上滑（推荐）
  static Widget _buildFadeSlide(CurvedAnimation animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  /// 淡入 + 缩放（弹出效果）
  static Widget _buildFadeScale(CurvedAnimation animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }

  /// 从右侧滑入（层级导航）
  static Widget _buildSlideFromRight(CurvedAnimation animation, Widget child) {
    return SlideTransition(
      position: Tween(
        begin: const Offset(0.15, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

enum AetherTransitionType {
  fadeSlide,
  fadeScale,
  slideFromRight,
}

/// 便捷导航扩展
extension AetherNavigator on NavigatorState {
  /// 使用 Aether 转场推入页面
  Future<T?> pushAether<T>(
    Widget page, {
    AetherTransitionType type = AetherTransitionType.fadeSlide,
  }) {
    return push<T>(AetherPageRoute<T>(page: page, type: type));
  }
}
