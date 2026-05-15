import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 渐变进度条组件
///
/// 支持三种模式：
/// - linear: 线性进度条（视频/音乐播放）
/// - circular: 圆形进度指示器
/// - mini: 迷你进度条（卡片底部）
///
/// 特性：渐变填充 + hover 扩展 + 拖拽圆点发光
class AetherProgress extends StatefulWidget {
  /// 当前进度 (0.0 ~ 1.0)
  final double value;

  /// 进度条高度
  final double height;

  /// 是否可交互（显示拖拽圆点）
  final bool interactive;

  /// 进度变化回调
  final ValueChanged<double>? onChanged;

  /// 自定义渐变色
  final Gradient? gradient;

  /// 轨道颜色
  final Color? trackColor;

  /// 是否显示时间标签
  final bool showLabels;

  /// 已播放时间
  final String? elapsed;

  /// 剩余/总时间
  final String? remaining;

  /// 模式
  final AetherProgressMode mode;

  const AetherProgress({
    super.key,
    required this.value,
    this.height = 4,
    this.interactive = false,
    this.onChanged,
    this.gradient,
    this.trackColor,
    this.showLabels = false,
    this.elapsed,
    this.remaining,
    this.mode = AetherProgressMode.linear,
  });

  /// 视频播放进度条（带时间标签）
  const AetherProgress.video({
    super.key,
    required this.value,
    this.height = 4,
    this.onChanged,
    this.elapsed,
    this.remaining,
  })  : interactive = true,
        gradient = AppColors.progressGradient,
        trackColor = null,
        showLabels = true,
        mode = AetherProgressMode.linear;

  /// 卡片底部迷你进度条
  const AetherProgress.mini({
    super.key,
    required this.value,
    this.height = 3,
  })  : interactive = false,
        gradient = AppColors.progressGradient,
        trackColor = null,
        showLabels = false,
        elapsed = null,
        remaining = null,
        onChanged = null,
        mode = AetherProgressMode.linear;

  /// 圆形进度指示器
  const AetherProgress.circular({
    super.key,
    required this.value,
    this.height = 4,
    this.gradient,
  })  : interactive = false,
        trackColor = null,
        showLabels = false,
        elapsed = null,
        remaining = null,
        onChanged = null,
        mode = AetherProgressMode.circular;

  @override
  State<AetherProgress> createState() => _AetherProgressState();
}

enum AetherProgressMode { linear, circular }

class _AetherProgressState extends State<AetherProgress>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isDragging = false;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.interactive) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AetherProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interactive && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.interactive) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == AetherProgressMode.circular) {
      return _buildCircular();
    }
    return _buildLinear();
  }

  Widget _buildCircular() {
    return SizedBox(
      width: widget.height * 2,
      height: widget.height * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 轨道
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: widget.height / 2,
            color: widget.trackColor ?? AppColors.cosmicGray,
          ),
          // 进度
          CircularProgressIndicator(
            value: widget.value.clamp(0.0, 1.0),
            strokeWidth: widget.height / 2,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.celestialCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinear() {
    final clampedValue = widget.value.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabels && widget.elapsed != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.elapsed!,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: widget.interactive
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          child: GestureDetector(
            onHorizontalDragStart: widget.interactive
                ? (details) {
                    setState(() => _isDragging = true);
                    _seekToPosition(details);
                  }
                : null,
            onHorizontalDragUpdate: widget.interactive
                ? (details) => _seekToPosition(details)
                : null,
            onHorizontalDragEnd: widget.interactive
                ? (_) => setState(() => _isDragging = false)
                : null,
            onTapDown: widget.interactive
                ? (details) => _seekToPosition(details)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: _isHovered ? 6.0 : widget.height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // 轨道
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: widget.trackColor ?? AppColors.cosmicGray,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          // 已播放
                          FractionallySizedBox(
                            widthFactor: clampedValue,
                            child: Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: widget.gradient,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  if (_isHovered || _isDragging)
                                    BoxShadow(
                                      color: AppColors.celestialCyan.withValues(
                                        alpha: 0.4 * _glowAnimation.value,
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // 拖拽圆点
                          if (widget.interactive && (_isHovered || _isDragging))
                            Positioned(
                              left: (constraints.maxWidth * clampedValue) - 7,
                              top: (constraints.maxHeight / 2) - 7,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.celestialCyan,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.celestialCyan.withValues(
                                        alpha: 0.6 * _glowAnimation.value,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.showLabels && widget.remaining != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.remaining!,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  void _seekToPosition(dynamic details) {
    if (widget.onChanged == null) return;
    // Simplified: assume the progress bar fills the parent width
    final RenderBox? renderBox =
        context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final ratio = (details.localPosition.dx / renderBox.size.width)
        .clamp(0.0, 1.0);
    widget.onChanged!(ratio);
  }
}
