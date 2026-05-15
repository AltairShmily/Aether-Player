import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 骨架屏加载组件
///
/// 在内容加载时显示与最终布局形状一致的占位块，
/// 使用微光脉动动画避免突兀的空白感。
class AetherSkeleton extends StatefulWidget {
  /// 骨架屏宽度，null 表示填满父容器
  final double? width;

  /// 骨架屏高度
  final double height;

  /// 圆角半径
  final double borderRadius;

  /// 形状：rectangle / circle / rounded
  final AetherSkeletonShape shape;

  const AetherSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.shape = AetherSkeletonShape.rectangle,
  });

  /// 卡片骨架
  const AetherSkeleton.card({
    super.key,
    this.width,
    this.height = 200,
  })  : borderRadius = 16,
        shape = AetherSkeletonShape.rounded;

  /// 头像骨架
  const AetherSkeleton.avatar({
    super.key,
    this.width = 48,
    this.height = 48,
  })  : borderRadius = 24,
        shape = AetherSkeletonShape.circle;

  /// 文字行骨架
  const AetherSkeleton.text({
    super.key,
    this.width,
    this.height = 14,
  })  : borderRadius = 6,
        shape = AetherSkeletonShape.rectangle;

  /// 标题骨架
  const AetherSkeleton.title({
    super.key,
    this.width,
    this.height = 20,
  })  : borderRadius = 6,
        shape = AetherSkeletonShape.rectangle;

  @override
  State<AetherSkeleton> createState() => _AetherSkeletonState();
}

enum AetherSkeletonShape { rectangle, circle, rounded }

class _AetherSkeletonState extends State<AetherSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.shape == AetherSkeletonShape.circle
        ? (widget.width ?? widget.height) / 2
        : widget.borderRadius;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _animation.value, 0),
              end: Alignment(-0.5 + 2.0 * _animation.value, 0),
              colors: const [
                Color(0xFF0E1319),
                Color(0xFF1A2332),
                Color(0xFF0E1319),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 预定义的骨架屏布局组件

/// 首页卡片列表骨架
class AetherHomeSkeleton extends StatelessWidget {
  const AetherHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Hero Banner 骨架
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AetherSkeleton(
              height: 200,
              borderRadius: 16,
              shape: AetherSkeletonShape.rounded,
            ),
          ),
        ),
        // 分类标题骨架
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                AetherSkeleton.text(width: 120, height: 12),
                const Spacer(),
                AetherSkeleton.text(width: 60, height: 10),
              ],
            ),
          ),
        ),
        // 卡片行骨架
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => const AetherSkeleton.card(),
            ),
          ),
        ),
        // 第二个分类骨架
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: AetherSkeleton.text(width: 100, height: 12),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => const AetherSkeleton.card(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 详情页骨架
class AetherDetailSkeleton extends StatelessWidget {
  const AetherDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero 区域骨架
          AetherSkeleton(
            height: 300,
            width: double.infinity,
            borderRadius: 0,
          ),
          const SizedBox(height: 24),
          // 内容区
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 海报
                AetherSkeleton.card(width: 120, height: 180),
                const SizedBox(width: 20),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AetherSkeleton.title(width: 200, height: 24),
                      SizedBox(height: 12),
                      AetherSkeleton.text(width: 140, height: 14),
                      SizedBox(height: 8),
                      AetherSkeleton.text(width: 100, height: 14),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          AetherSkeleton(width: 100, height: 40, borderRadius: 12),
                          SizedBox(width: 12),
                          AetherSkeleton(width: 100, height: 40, borderRadius: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 简介骨架
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AetherSkeleton.text(width: 80, height: 12),
                SizedBox(height: 12),
                AetherSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 8),
                AetherSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 8),
                AetherSkeleton(width: 200, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
