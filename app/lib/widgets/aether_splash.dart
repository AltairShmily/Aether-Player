import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether 启动/加载动画页面
///
/// 展示 Logo 脉动 + 星空粒子背景。
/// 用于应用启动、数据加载、版本更新等场景。
class AetherSplash extends StatefulWidget {
  final String? subtitle;
  final VoidCallback? onComplete;

  const AetherSplash({
    super.key,
    this.subtitle,
    this.onComplete,
  });

  @override
  State<AetherSplash> createState() => _AetherSplashState();
}

class _AetherSplashState extends State<AetherSplash>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _starController;
  late final AnimationController _fadeController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoGlow;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // Logo 脉动
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoGlow = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // 星空粒子
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // 整体淡入
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _fadeController.forward();
    await _logoController.forward();

    // 如果有回调，延迟后执行
    if (widget.onComplete != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _starController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Stack(
        children: [
          // ── 星空粒子 ──
          AnimatedBuilder(
            animation: _starController,
            builder: (context, _) => CustomPaint(
              painter: _SplashStarPainter(
                animation: _starController.value,
              ),
              size: Size.infinite,
            ),
          ),

          // ── 径向光晕 ──
          AnimatedBuilder(
            animation: _logoGlow,
            builder: (context, _) => Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [
                      AppColors.celestialCyan
                          .withValues(alpha: 0.08 * _logoGlow.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 内容 ──
          AnimatedBuilder(
            animation: _fadeIn,
            builder: (context, child) => Opacity(
              opacity: _fadeIn.value,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    AnimatedBuilder(
                      animation: _logoScale,
                      builder: (context, child) => Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                      child: AnimatedBuilder(
                        animation: _logoGlow,
                        builder: (context, child) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.celestialCyan.withValues(
                                  alpha: 0.4 * _logoGlow.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.deepVoid,
                            size: 44,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 标题
                    const Text(
                      'AETHER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 副标题
                    Text(
                      widget.subtitle ?? '连接你的媒体宇宙',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 加载指示器
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.celestialCyan.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 星空粒子绘制器
class _SplashStarPainter extends CustomPainter {
  final double animation;
  final List<_Star> _stars;

  _SplashStarPainter({required this.animation})
      : _stars = List.generate(60, (i) => _Star.random(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle = (sin(animation * 2 * pi + star.phase) + 1) / 2;
      final opacity = 0.1 + twinkle * 0.3;
      final paint = Paint()
        ..color = star.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.blur);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashStarPainter old) => old.animation != animation;
}

class _Star {
  final double x, y, radius, phase, blur;
  final Color color;

  _Star(this.x, this.y, this.radius, this.phase, this.blur, this.color);

  factory _Star.random(int seed) {
    final r = Random(seed);
    final colors = [
      AppColors.celestialCyan,
      AppColors.novaPurple,
      AppColors.auroraGreen,
      Colors.white,
    ];
    return _Star(
      r.nextDouble(),
      r.nextDouble(),
      0.3 + r.nextDouble() * 1.2,
      r.nextDouble() * 2 * pi,
      0.2 + r.nextDouble() * 0.5,
      colors[r.nextInt(colors.length)],
    );
  }
}
