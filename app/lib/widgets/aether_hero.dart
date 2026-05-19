import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Aether Hero Banner 组件
///
/// 全宽沉浸式横幅，用于首页轮播和详情页头部。
/// 支持背景图 + 渐变遮罩 + 毛玻璃 + 内容叠加。
class AetherHero extends StatelessWidget {
  /// 背景图片 URL
  final String? imageUrl;

  /// 背景图片网络请求头
  final Map<String, String>? headers;

  /// 标题
  final String? title;

  /// 副标题
  final String? subtitle;

  /// 标题下方的小标签列表
  final List<String> tags;

  /// 评分 (0 = 不显示)
  final double rating;

  /// 主要操作按钮
  final Widget? primaryAction;

  /// 次要操作按钮
  final Widget? secondaryAction;

  /// 底部内容（覆盖在渐变上）
  final Widget? bottomContent;

  /// 高度
  final double height;

  /// 是否启用模糊背景
  final bool enableBlur;

  /// 遮罩渐变色
  final List<Color>? overlayColors;

  /// 点击回调（整个 Hero 可点击）
  final VoidCallback? onTap;

  /// 是否使用左侧渐变（carousel / featured 模式）
  final bool _useLeftGradient;

  const AetherHero({
    super.key,
    this.imageUrl,
    this.headers,
    this.title,
    this.subtitle,
    this.tags = const [],
    this.rating = 0,
    this.primaryAction,
    this.secondaryAction,
    this.bottomContent,
    this.height = 360,
    this.enableBlur = true,
    this.overlayColors,
    this.onTap,
  }) : _useLeftGradient = false;

  /// 首页轮播 Hero
  const AetherHero.carousel({
    super.key,
    this.imageUrl,
    this.headers,
    this.title,
    this.subtitle,
    this.tags = const [],
    this.rating = 0,
    this.primaryAction,
    this.secondaryAction,
    this.height = 300,
    this.onTap,
  })  : bottomContent = null,
        enableBlur = false,
        overlayColors = null,
        _useLeftGradient = true;

  /// 大尺寸 Featured Banner (3:1)
  const AetherHero.featured({
    super.key,
    this.imageUrl,
    this.headers,
    this.title,
    this.subtitle,
    this.tags = const [],
    this.rating = 0,
    this.primaryAction,
    this.secondaryAction,
    this.height = 300,
    this.onTap,
  })  : bottomContent = null,
        enableBlur = false,
        overlayColors = null,
        _useLeftGradient = true;

  /// 详情页 Hero
  const AetherHero.detail({
    super.key,
    this.imageUrl,
    this.headers,
    this.title,
    this.subtitle,
    this.tags = const [],
    this.rating = 0,
    this.primaryAction,
    this.secondaryAction,
    this.bottomContent,
    this.height = 400,
    this.onTap,
  })  : enableBlur = true,
        overlayColors = null,
        _useLeftGradient = false;

  @override
  Widget build(BuildContext context) {
    final overlays = overlayColors ??
        [
          Colors.transparent,
          Colors.transparent,
          AppColors.deepVoid.withValues(alpha: 0.6),
          AppColors.deepVoid,
        ];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 背景图 ──
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                headers: headers ?? const {'Accept': 'image/*'},
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            // ── 模糊层 ──
            if (enableBlur)
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 20),
                  child: Container(color: Colors.transparent),
                ),
              ),

            // ── 渐变遮罩 ──
            if (_useLeftGradient) ...[
              // 左侧渐变（StreamVault 风格）
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Color(0xD90A0E14), // rgba(10,14,20,0.85)
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
              // 底部渐变
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.deepVoid,
                      ],
                    ),
                  ),
                ),
              ),
            ] else
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: overlays,
                      stops: const [0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

            // ── 微光边框 (底部) ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.celestialCyan,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── 内容 ──
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 标签
                    if (tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.chipBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                    // 评分
                    if (rating > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 18, color: AppColors.supernova),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.supernova,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DM Mono',
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 标题
                    if (title != null)
                      Text(
                        title!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // 副标题
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // 按钮
                    if (primaryAction != null || secondaryAction != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            if (primaryAction != null) primaryAction!,
                            if (primaryAction != null && secondaryAction != null)
                              const SizedBox(width: 12),
                            if (secondaryAction != null) secondaryAction!,
                          ],
                        ),
                      ),

                    // 自定义底部内容
                    if (bottomContent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: bottomContent!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.nebulaDark,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          size: 64,
          color: AppColors.cosmicGray,
        ),
      ),
    );
  }
}
