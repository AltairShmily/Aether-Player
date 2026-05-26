import 'package:flutter/material.dart';

/// Aether Player 色彩系统 V3 — Celestial Glow Theme
///
/// StreamVault 布局结构 + Celestial Glow 色系融合方案。
/// 保留 V1/V2 旧名称作为兼容别名，新代码请使用 V3 名称。
class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════
  //  V2 — 深空背景
  // ══════════════════════════════════════════════════
  static const Color deepVoid = Color(0xFF0A0E14);
  static const Color bgPrimary = Color(0xFF0D1520);    // --bg-primary
  static const Color bgSecondary = Color(0xFF0F1722);  // --bg-secondary
  static const Color nebulaDark = Color(0xFF111820);    // --bg-surface / --bg-card
  static const Color stardust = Color(0xFF1A2332);      // --bg-surface-hover / --bg-elevated
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
  static const Color borderDefault = Color(0x0FFFFFFF); // 6% rgba(255,255,255,0.06)
  static const Color borderSubtle = Color(0x1AFFFFFF);  // 10% rgba(255,255,255,0.10)
  static const Color borderFocus = Color(0x4D00D4FF);  // 30% celestialCyan

  // ══════════════════════════════════════════════════
  //  V3 — 交互态
  // ══════════════════════════════════════════════════
  static const Color surfaceHover = Color(0xFF1A2332);    // 卡片悬浮态
  static const Color accentHover = Color(0xFF33DDFF);     // 强调色悬浮
  static const Color accentSoft = Color(0x1A00D4FF);      // --accent-soft 10%
  static const Color accentMedium = Color(0x3300D4FF);    // --accent-medium 20%
  static const Color accentGlow = Color(0x4000D4FF);      // 发光效果 rgba(0,212,255,0.25)
  static const Color borderLight = Color(0x1AFFFFFF);     // 边框亮色 rgba(255,255,255,0.10)

  // ══════════════════════════════════════════════════
  //  V3 — 圆角设计令牌
  // ══════════════════════════════════════════════════
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ══════════════════════════════════════════════════
  //  V3 — 渐变色板 (回退用)
  // ══════════════════════════════════════════════════
  static const List<Color> gradientPalette = [
    Color(0xFF0A0E14), // deepVoid
    Color(0xFF111820), // nebulaDark
    Color(0xFF1A2332), // stardust
    Color(0xFF8B5CF6), // novaPurple
    Color(0xFF00D4FF), // celestialCyan
    Color(0xFF00E5A0), // auroraGreen
    Color(0xFFFF6B35), // supernova
    Color(0xFFEC4899), // plasmaPink
  ];

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
