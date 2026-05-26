import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 自定义下拉选择器 — 匹配 Celestial Glow 设计稿
///
/// 用于剧集详情页的媒体源/音频/字幕选择。
/// 非原生 select，完全自定义样式。
class AetherDropdown extends StatefulWidget {
  /// 分组标题（如 "媒体源"、"音频"、"字幕"）
  final String label;

  /// 选项列表
  final List<AetherDropdownOption> options;

  /// 当前选中索引
  final int selectedIndex;

  /// 选项变更回调
  final ValueChanged<int> onChanged;

  const AetherDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  State<AetherDropdown> createState() => _AetherDropdownState();
}

class _AetherDropdownState extends State<AetherDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.options[widget.selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 7),
        // 触发器
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.stardust,
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(
                color: _isOpen
                    ? AppColors.celestialCyan
                    : AppColors.borderLight,
              ),
              boxShadow: _isOpen
                  ? [
                      BoxShadow(
                        color: AppColors.celestialCyan.withValues(alpha: 0.1),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: selected.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (selected.subtitle != null)
                          TextSpan(
                            text: ' ${selected.subtitle}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.expand_more,
                    size: 17,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 下拉菜单
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
            );
          },
          child: _isOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.stardust,
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.options.length; i++)
                          _buildOption(i, widget.options[i]),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildOption(int index, AetherDropdownOption option) {
    final isSelected = index == widget.selectedIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          widget.onChanged(index);
          _close();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.celestialCyan.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusXs),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: option.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.celestialCyan
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                      if (option.subtitle != null)
                        TextSpan(
                          text: ' ${option.subtitle}',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.celestialCyan.withValues(alpha: 0.7)
                                : AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.check,
                size: 17,
                color: isSelected
                    ? AppColors.celestialCyan
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 下拉选项数据
class AetherDropdownOption {
  final String label;
  final String? subtitle;

  const AetherDropdownOption({
    required this.label,
    this.subtitle,
  });
}
