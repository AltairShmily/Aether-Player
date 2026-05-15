import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Aether Player 主题系统 V2 — Celestial Glow
///
/// 基于 Material 3，融合深空美学。
/// 支持 dynamicColor 回退到 Aether 星辰主题。
class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════
  //  深空色板 (当 dynamicColor 不可用时使用)
  // ══════════════════════════════════════════════════
  static const _seed = AppColors.celestialCyan;

  static final ColorScheme _aetherColorScheme = ColorScheme.dark(
    primary: AppColors.celestialCyan,
    onPrimary: AppColors.deepVoid,
    primaryContainer: AppColors.celestialCyan.withValues(alpha: 0.15),
    onPrimaryContainer: AppColors.celestialCyan,

    secondary: AppColors.novaPurple,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.novaPurple.withValues(alpha: 0.15),
    onSecondaryContainer: AppColors.novaPurple,

    tertiary: AppColors.auroraGreen,
    onTertiary: AppColors.deepVoid,
    tertiaryContainer: AppColors.auroraGreen.withValues(alpha: 0.12),
    onTertiaryContainer: AppColors.auroraGreen,

    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.error.withValues(alpha: 0.12),
    onErrorContainer: AppColors.error,

    surface: AppColors.nebulaDark,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,

    outline: AppColors.cosmicGray,
    outlineVariant: AppColors.borderSubtle,

    shadow: Colors.black,
    scrim: Colors.black54,
    surfaceTint: AppColors.celestialCyan,
    surfaceContainerHighest: AppColors.stardust,
    surfaceContainerHigh: AppColors.nebulaDark,
    surfaceContainer: Color(0xFF0E1319),
    surfaceContainerLow: AppColors.deepVoid,
    surfaceContainerLowest: Color(0xFF060A0F),
  );

  // ══════════════════════════════════════════════════
  //  公开方法
  // ══════════════════════════════════════════════════

  static ThemeData darkTheme({ColorScheme? dynamicScheme}) {
    final colorScheme = dynamicScheme ?? _aetherColorScheme;
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.deepVoid,
      textTheme: textTheme,

      // ── 导航 ──
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.nebulaDark,
        elevation: 0,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 22,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.textSecondary,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        indicatorSize: NavigationRailIndicatorSize.all,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.nebulaDark,
        elevation: 0,
        height: 64,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.3,
            );
          }
          return TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 22);
          }
          return IconThemeData(color: AppColors.textSecondary, size: 22);
        }),
      ),

      // ── 输入框 ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.stardust,
        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── 按钮 ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: AppColors.deepVoid,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.borderSubtle),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      // ── 卡片 ──
      cardTheme: CardThemeData(
        color: AppColors.nebulaDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── 分割线 ──
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      // ── 对话框 ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.stardust,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      // ── 底部弹窗 ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.stardust,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        modalBarrierColor: Colors.black54,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.stardust,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBg,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        side: const BorderSide(color: AppColors.borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── 进度条 ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.celestialCyan,
        linearTrackColor: AppColors.cosmicGray,
      ),

      // ── Slider ──
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: AppColors.cosmicGray,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.deepVoid;
          }
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return AppColors.cosmicGray;
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  文字样式快捷方法
  // ══════════════════════════════════════════════════

  /// 代码/时码 字体 (JetBrains Mono)
  static TextStyle mono({
    double size = 13,
    Color color = AppColors.textSecondary,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: 0.5,
    );
  }

  /// 章节标题 (杂志感)
  static TextStyle sectionTitle({
    double size = 13,
    Color color = AppColors.textTertiary,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: 3,
      color: color,
    );
  }
}
