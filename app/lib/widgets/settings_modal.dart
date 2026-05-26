import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';

/// 设置弹窗 — 匹配 Celestial Glow 设计稿
///
/// 覆盖层 + 毛玻璃背景 + 居中弹窗
class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  /// 显示设置弹窗的静态方法
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SettingsModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final _settingsService = SettingsService();
  bool _autoPlayNext = true;
  bool _hardwareAcceleration = true;
  bool _noiseTexture = true;
  bool _animations = true;
  bool _remoteAccess = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoPlay = await _settingsService.getAutoPlayNext();
    final hwAccel = await _settingsService.getHardwareAcceleration();
    final noise = await _settingsService.getNoiseTexture();
    final anim = await _settingsService.getAnimations();
    final remote = await _settingsService.getRemoteAccess();
    if (mounted) {
      setState(() {
        _autoPlayNext = autoPlay;
        _hardwareAcceleration = hwAccel;
        _noiseTexture = noise;
        _animations = anim;
        _remoteAccess = remote;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppColors.radiusXl),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 64,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 头部 ──
              _buildHeader(),
              // ── 内容 ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 播放设置
                      _SettingsGroup(
                        title: '播放',
                        children: [
                          _SettingsRow(
                            label: '自动播放下一集',
                            description: '当前集结束后自动播放下一集',
                            trailing: _AetherToggle(
                              value: _autoPlayNext,
                              onChanged: (v) {
                                setState(() => _autoPlayNext = v);
                                _settingsService.setAutoPlayNext(v);
                              },
                            ),
                          ),
                          _SettingsRow(
                            label: '默认画质',
                            description: '默认使用的媒体源画质',
                            trailingValue: '原始画质',
                          ),
                          _SettingsRow(
                            label: '硬件加速',
                            description: '使用 GPU 进行视频解码',
                            trailing: _AetherToggle(
                              value: _hardwareAcceleration,
                              onChanged: (v) {
                                setState(() => _hardwareAcceleration = v);
                                _settingsService.setHardwareAcceleration(v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 外观设置
                      _SettingsGroup(
                        title: '外观',
                        children: [
                          _SettingsRow(
                            label: '深色模式',
                            description: '界面主题颜色方案',
                            trailingValue: '深色',
                          ),
                          _SettingsRow(
                            label: '噪点纹理',
                            description: '界面元素启用噪点效果',
                            trailing: _AetherToggle(
                              value: _noiseTexture,
                              onChanged: (v) {
                                setState(() => _noiseTexture = v);
                                _settingsService.setNoiseTexture(v);
                              },
                            ),
                          ),
                          _SettingsRow(
                            label: '动画效果',
                            description: '页面切换和交互动画',
                            trailing: _AetherToggle(
                              value: _animations,
                              onChanged: (v) {
                                setState(() => _animations = v);
                                _settingsService.setAnimations(v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 网络设置
                      _SettingsGroup(
                        title: '网络',
                        children: [
                          _SettingsRow(
                            label: '远程访问',
                            description: '允许通过互联网连接服务器',
                            trailing: _AetherToggle(
                              value: _remoteAccess,
                              onChanged: (v) {
                                setState(() => _remoteAccess = v);
                                _settingsService.setRemoteAccess(v);
                              },
                            ),
                          ),
                          _SettingsRow(
                            label: '带宽限制',
                            description: '远程播放时的最大带宽',
                            trailingValue: '自动',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.nebulaDark,
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  _SettingsGroup — 设置分组
// ══════════════════════════════════════════════════
class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.celestialCyan,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

// ══════════════════════════════════════════════════
//  _SettingsRow — 设置行（标签 + 描述 + 控件）
// ══════════════════════════════════════════════════
class _SettingsRow extends StatelessWidget {
  final String label;
  final String? description;
  final Widget? trailing;
  final String? trailingValue;

  const _SettingsRow({
    required this.label,
    this.description,
    this.trailing,
    this.trailingValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingValue != null)
            Text(
              trailingValue!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  _AetherToggle — 动画开关（设计稿样式）
// ══════════════════════════════════════════════════
class _AetherToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AetherToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.celestialCyan : AppColors.stardust,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppColors.celestialCyan
                : AppColors.borderLight,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: value ? AppColors.deepVoid : AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
