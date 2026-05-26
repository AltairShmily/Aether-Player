import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// 全屏搜索叠加层 (Ctrl+K / Cmd+K 触发)
///
/// 灵感来自 StreamVault 的搜索设计：毛玻璃背景 + 居中搜索框 + 流畅缩放动画。
/// 通过 [SearchOverlay.show] 静态方法以透明路由方式弹出。
///
/// 使用示例:
/// ```dart
/// // 快捷键绑定
/// LogicalKeyboardKey.space → 不适用
/// RawKeyboardListener(
///   onKey: (event) {
///     if ((HardwareKeyboard.instance.isControlPressed || ...isMetaPressed)
///         && event.key == LogicalKeyboardKey.keyK) {
///       SearchOverlay.show(context);
///     }
///   },
/// )
/// ```
class SearchOverlay extends StatefulWidget {
  /// 搜索提交回调，返回用户输入的查询字符串。
  final ValueChanged<String>? onSubmitted;

  /// 预填充的搜索文本（可选）。
  final String initialQuery;

  const SearchOverlay({
    super.key,
    this.onSubmitted,
    this.initialQuery = '',
  });

  /// 以透明路由方式展示搜索叠加层。
  ///
  /// [context] 用于导航；[onSubmitted] 在用户提交搜索时触发。
  /// 路由返回时会自动 pop。
  static Future<void> show(
    BuildContext context, {
    ValueChanged<String>? onSubmitted,
  }) {
    return Navigator.of(context).push(_SearchOverlayRoute(
      onSubmitted: onSubmitted,
    ));
  }

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

// ═══════════════════════════════════════════════════════════════
//  透明路由
// ═══════════════════════════════════════════════════════════════

/// 自定义透明路由，使 [SearchOverlay] 可以以 modal 方式弹出，
/// 背后内容仍然可见（配合 BackdropFilter 实现毛玻璃）。
class _SearchOverlayRoute extends PageRouteBuilder<void> {
  final ValueChanged<String>? onSubmitted;

  _SearchOverlayRoute({this.onSubmitted})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) {
            return SearchOverlay(onSubmitted: onSubmitted);
          },
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  State
// ═══════════════════════════════════════════════════════════════

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    // ── 动画设置 ──
    // 缩放: 0.97 → 1.0，弹性 cubic-bezier
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // ── 打开时自动聚焦输入框 ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── 关闭叠加层 ──
  void _close() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // ── 提交搜索 ──
  void _handleSubmit(String query) {
    if (query.trim().isEmpty) return;
    widget.onSubmitted?.call(query.trim());
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── 毛玻璃背景遮罩 ──
          _buildBackdrop(),

          // ── 搜索面板 ──
          _buildSearchPanel(),
        ],
      ),
    );
  }

  /// 毛玻璃背景：深色遮罩 + 高斯模糊
  Widget _buildBackdrop() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: GestureDetector(
            onTap: _close,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: const Color(0x8C000000), // rgba(0,0,0,0.55)
              ),
            ),
          ),
        );
      },
    );
  }

  /// 居中搜索面板
  Widget _buildSearchPanel() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 600
                      ? 24
                      : 48,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildSearchBox(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 搜索输入框
  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stardust,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.celestialCyan.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 搜索输入行 ──
          _buildInputRow(),
          // ── 底部分割线 ──
          Container(
            height: 1,
            color: AppColors.borderSubtle,
          ),
          // ── 提示文字 ──
          _buildHintBar(),
        ],
      ),
    );
  }

  /// 搜索图标 + 文本输入
  Widget _buildInputRow() {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        // Esc 关闭
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _close();
        }
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: '搜索电影、电视剧、演员...',
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 16,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.celestialCyan,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 18,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _handleSubmit,
      ),
    );
  }

  /// 底部快捷键提示
  Widget _buildHintBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '输入关键词搜索，或按 Esc 关闭',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
