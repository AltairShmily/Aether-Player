import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 可复用的横向滚动包装器，添加左右箭头按钮和鼠标拖拽支持。
///
/// 包装一个可滚动子组件（如横向 ListView），显示半透明圆形箭头按钮，
/// 在 hover 时出现。箭头每次点击滚动 350px，滚动到边界时自动隐藏。
/// 支持鼠标拖拽滚动。
///
/// Usage:
/// ```dart
/// ScrollArrows(
///   scrollController: _controller,
///   child: ListView.separated(
///     controller: _controller,
///     scrollDirection: Axis.horizontal,
///     itemCount: items.length,
///     itemBuilder: (context, index) => items[index],
///   ),
/// )
/// ```
class ScrollArrows extends StatefulWidget {
  /// The scroll controller attached to the scrollable child.
  final ScrollController scrollController;

  /// The scrollable child widget (e.g., ListView, SingleChildScrollView).
  final Widget child;

  /// Pixel amount to scroll per arrow click. Defaults to 350.
  final double scrollAmount;

  /// Arrow button size in pixels. Defaults to 36.
  final double arrowSize;

  /// Horizontal inset from the edge. Defaults to 4.
  final double arrowInset;

  const ScrollArrows({
    super.key,
    required this.scrollController,
    required this.child,
    this.scrollAmount = 350,
    this.arrowSize = 36,
    this.arrowInset = 4,
  });

  @override
  State<ScrollArrows> createState() => _ScrollArrowsState();
}

class _ScrollArrowsState extends State<ScrollArrows> {
  bool _isHovered = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  // 拖拽状态
  bool _isDragging = false;
  double _dragStartX = 0;
  double _dragStartScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateScrollState);
    // Check initial state after the first frame renders.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  @override
  void didUpdateWidget(ScrollArrows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_updateScrollState);
      widget.scrollController.addListener(_updateScrollState);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateScrollState);
    super.dispose();
  }

  void _updateScrollState() {
    if (!mounted) return;
    final controller = widget.scrollController;
    final hasClients = controller.hasClients;
    if (!hasClients) return;

    final position = controller.position;
    final canLeft = position.pixels > position.minScrollExtent;
    final canRight = position.pixels < position.maxScrollExtent;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollLeft() {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final target = (controller.offset - widget.scrollAmount).clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRight() {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final target = (controller.offset + widget.scrollAmount).clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // ── 鼠标拖拽处理 ──

  void _onDragStart(PointerDownEvent event) {
    _isDragging = true;
    _dragStartX = event.position.dx;
    _dragStartScrollOffset = widget.scrollController.offset;
  }

  void _onDragMove(PointerMoveEvent event) {
    if (!_isDragging) return;
    final dx = event.position.dx - _dragStartX;
    final newOffset = (_dragStartScrollOffset - dx * 1.5).clamp(
      widget.scrollController.position.minScrollExtent,
      widget.scrollController.position.maxScrollExtent,
    );
    widget.scrollController.jumpTo(newOffset);
  }

  void _onDragEnd(PointerUpEvent event) {
    _isDragging = false;
  }

  void _onDragCancel(PointerCancelEvent event) {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isDragging = false;
      }),
      cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: Listener(
        onPointerDown: _onDragStart,
        onPointerMove: _onDragMove,
        onPointerUp: _onDragEnd,
        onPointerCancel: _onDragCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            // Left arrow
            if (_canScrollLeft)
              Positioned(
                left: widget.arrowInset,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _isHovered && !_isDragging ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: _ArrowButton(
                      direction: _ArrowDirection.left,
                      size: widget.arrowSize,
                      onTap: _scrollLeft,
                    ),
                  ),
                ),
              ),
            // Right arrow
            if (_canScrollRight)
              Positioned(
                right: widget.arrowInset,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _isHovered && !_isDragging ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: _ArrowButton(
                      direction: _ArrowDirection.right,
                      size: widget.arrowSize,
                      onTap: _scrollRight,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  _ArrowButton — internal circular arrow button
// ─────────────────────────────────────────────────────

enum _ArrowDirection { left, right }

class _ArrowButton extends StatefulWidget {
  final _ArrowDirection direction;
  final double size;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.direction,
    required this.size,
    required this.onTap,
  });

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _isButtonHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.direction == _ArrowDirection.left;
    final color = AppColors.nebulaDark;
    final bgColor = _isButtonHovered
        ? AppColors.celestialCyan.withValues(alpha: 0.10)
        : color.withValues(alpha: 0.90);
    final borderColor = _isButtonHovered
        ? AppColors.celestialCyan
        : AppColors.borderSubtle;
    final iconColor = _isButtonHovered
        ? AppColors.celestialCyan
        : AppColors.textSecondary;
    final icon = isLeft
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
