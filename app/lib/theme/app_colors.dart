import 'dart:ui';

import 'package:flutter/material.dart';

/// Aether Player 色彩系统 V2 — Celestial Glow Theme
///
/// 以深空为基底，星辰为点缀，构建层次丰富的视觉语言。
/// 保留 V1 旧名称作为兼容别名，新代码请使用 V2 名称。
class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════
  //  V2 — 深空背景
  // ══════════════════════════════════════════════════
  static const Color deepVoid = Color(0xFF0A0E14);
  static const Color nebulaDark = Color(0xFF111820);
  static const Color stardust = Color(0xFF1A2332);
  static const Color cosmicGray = Color(0xFF2A3444);

  // ══════════════════════════════════════════════════
  //  V2 — 星辰强调色
  // ══════════════════════════════════════════════════
  static const Color celestialCyan = Color(0xFF00D4FF);
  static const Color auroraGreen = Color(0xFF00E5A0);
  static const Color supernova = Color(0xFFFF6B35);
  static const Color novaPurple = Color(0xFF8B5CF6);
  static const Color plasmaPink = Color(0xFFEC4899);

  // ══════════════════════════════════════════════════
  //  V2 — 文字
  // ══════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textTertiary = Color(0xFF5A6577);

  // ══════════════════════════════════════════════════
  //  V2 — 功能色
  // ══════════════════════════════════════════════════
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFF6B35);
  static const Color error = Color(0xFFEF4444);

  // ══════════════════════════════════════════════════
  //  V2 — 边框
  // ══════════════════════════════════════════════════
  static const Color borderSubtle = Color(0x1AFFFFFF); // 10%
  static const Color borderFocus = Color(0x4D00D4FF); // 30% celestialCyan

  // ══════════════════════════════════════════════════
  //  V2 — 渐变
  // ══════════════════════════════════════════════════
  static const LinearGradient accentGradient = LinearGradient(
    colors: [celestialCyan, novaPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradientFull = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, deepVoid],
    stops: [0.4, 1.0],
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [celestialCyan, novaPurple],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x0AFFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ══════════════════════════════════════════════════
  //  V2 — 发光效果
  // ══════════════════════════════════════════════════
  static BoxShadow glowCyan({double blur = 20, double spread = 2}) {
    return BoxShadow(
      color: celestialCyan.withValues(alpha: 0.25),
      blurRadius: blur,
      spreadRadius: spread,
    );
  }

  static BoxShadow glowPurple({double blur = 20, double spread = 2}) {
    return BoxShadow(
      color: novaPurple.withValues(alpha: 0.25),
      blurRadius: blur,
      spreadRadius: spread,
    );
  }

  static BoxShadow glowGreen({double blur = 20, double spread = 2}) {
    return BoxShadow(
      color: auroraGreen.withValues(alpha: 0.25),
      blurRadius: blur,
      spreadRadius: spread,
    );
  }

  // ══════════════════════════════════════════════════
  //  V2 — 辅助方法
  // ══════════════════════════════════════════════════

  /// 根据背景色生成顶部到底部的渐变遮罩
  static LinearGradient heroGradient({required Color bgColor}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, bgColor],
      stops: const [0.4, 1.0],
    );
  }

  /// 获取文字颜色的强调色变体（用于强调文字场景）
  static Color textOnAccent = deepVoid;

  // ══════════════════════════════════════════════════
  //  V1 → V2 兼容别名
  //  旧代码仍可编译，新代码请直接使用 V2 名称
  // ══════════════════════════════════════════════════

  // 背景色
  static const Color episodeBg = stardust;           // 深橄榄棕 → 星尘
  static const Color seriesBg = nebulaDark;           // 深墨绿 → 星云暗
  static const Color cardBg = Color(0x15FFFFFF);      // rgba(255,255,255,0.08) 更通透
  static const Color chipBg = Color(0x1AFFFFFF);      // rgba(255,255,255,0.10)

  // 强调色
  static const Color playGold = celestialCyan;        // 暖金黄 → 星辰青
  static const Color playMint = auroraGreen;           // 薄荷绿 → 极光绿
  static const Color ratingStar = supernova;           // 评分星标红 → 超新星橙

  // 文字色
  static const Color textWarmGray = textSecondary;     // 暖灰 → 雾灰
  static const Color textCoolGray = auroraGreen;       // 冷灰绿 → 极光绿

  // 边框
  static const Color goldBorder = celestialCyan;       // 菱形徽章边框 → 星辰青
}
