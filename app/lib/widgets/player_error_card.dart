import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'aether_button.dart';

/// 播放失败时的居中错误卡片。
///
/// 取代原先贴在 bottom:120 的提示条：那条与 OSD 底栏抢同一层，
/// 且只有一句文案、没有任何下一步动作，用户看到失败只能自己退出去。
///
/// 三个动作按自救成功率排序：重试（同一地址重开）→ 切换画质
/// （直连失败换转码、转码失败换直连）→ 返回。
class PlayerErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onSwitchQuality;
  final VoidCallback? onBack;

  const PlayerErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.onSwitchQuality,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // 半透明遮罩把卡片与下层 OSD 分开，避免两层控件叠在一起分不清主次
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
            decoration: BoxDecoration(
              color: AppColors.stardust,
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
            ),
            // 播放页强制横屏，手机横屏可视高度只有 360-412dp，
            // 固定尺寸的 Column 必然溢出；可滚动才能适配所有屏幕
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '播放失败',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AetherButton.primary(
                    icon: Icons.refresh_rounded,
                    label: '重试',
                    compact: true,
                    width: double.infinity,
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: 8),
                  AetherButton.secondary(
                    icon: Icons.high_quality_rounded,
                    label: '切换画质',
                    compact: true,
                    width: double.infinity,
                    onPressed: onSwitchQuality,
                  ),
                  const SizedBox(height: 8),
                  AetherButton.ghost(
                    icon: Icons.close_rounded,
                    label: '返回',
                    compact: true,
                    width: double.infinity,
                    onPressed: onBack,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
