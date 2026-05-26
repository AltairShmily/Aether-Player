import 'dart:math';
import 'package:flutter/material.dart';

/// 噪点纹理覆盖组件
///
/// 模拟设计稿中的 SVG feTurbulence 效果，
/// 为界面添加细腻的噪点纹理质感。
/// 使用 CustomPainter 绘制随机噪点，opacity 默认 0.025。
class NoiseTexture extends StatelessWidget {
  /// 噪点透明度，默认 0.025 匹配设计稿
  final double opacity;

  /// 噪点密度，默认 800 个点
  final int density;

  const NoiseTexture({
    super.key,
    this.opacity = 0.025,
    this.density = 800,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _NoisePainter(
          opacity: opacity,
          density: density,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;
  final int density;

  _NoisePainter({required this.opacity, required this.density});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // 固定种子确保一致的噪点图案
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < density; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final brightness = random.nextDouble();

      paint.color = Color.fromRGBO(
        255,
        255,
        255,
        brightness * opacity,
      );

      canvas.drawRect(
        Rect.fromLTWH(x, y, 1, 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.density != density;
  }
}
