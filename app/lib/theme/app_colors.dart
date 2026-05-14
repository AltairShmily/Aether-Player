import 'package:flutter/material.dart';

/// Aether Player 颜色系统
class AppColors {
  AppColors._();

  // ── 背景色 ──
  static const Color episodeBg = Color(0xFF2A2218);      // 深橄榄棕 - 集数详情页
  static const Color seriesBg = Color(0xFF1A2E24);        // 深墨绿 - 剧集总览页
  static const Color cardBg = Color(0x47000000);           // rgba(0,0,0,0.28) 卡片背景
  static const Color chipBg = Color(0x1FFFFFFF);           // rgba(255,255,255,0.12) 标签背景

  // ── 强调色 ──
  static const Color playGold = Color(0xFFD4A843);         // 暖金黄 - 集数详情页播放按钮
  static const Color playMint = Color(0xFF7ECFB0);         // 薄荷绿 - 剧集总览页播放按钮
  static const Color ratingStar = Color(0xFFE04040);       // 评分星标红

  // ── 文字色 ──
  static const Color textPrimary = Color(0xFFFFFFFF);      // 主文字 白色
  static const Color textWarmGray = Color(0xFFB8A88A);     // 次要文字 暖灰
  static const Color textCoolGray = Color(0xFFA8C4B8);     // 次要文字 冷灰绿
  static const Color textSecondary = Color(0xB3FFFFFF);     // 70% 白色通用次要

  // ── 边框 ──
  static const Color borderSubtle = Color(0x33FFFFFF);      // rgba(255,255,255,0.2)
  static const Color goldBorder = Color(0xFFD4A843);        // 菱形徽章边框

  // ── 渐变遮罩 ──
  static LinearGradient heroGradient({required Color bgColor}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        bgColor,
      ],
      stops: const [0.5, 1.0],
    );
  }
}
