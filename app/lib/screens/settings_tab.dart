import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_breakpoints.dart';
import '../widgets/aether_card.dart';
import '../widgets/aether_button.dart';
import '../widgets/aether_badge.dart';
import 'server_selection_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final authState = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);
    final pad = AetherBreakpoints.pagePadding(context);
    final serverName = authState.authResult?.server.serverName ?? '';
    final userName = authState.authResult?.user.name ?? '';
    final serverUrl = '';

    return CustomScrollView(
      slivers: [
        // ── App Bar ──
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.deepVoid,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            '设置',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── 账户信息卡片 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
            child: AetherCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 头像
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.deepVoid,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          serverName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          serverUrl,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 在线状态
                  const AetherBadge.dot(),
                ],
              ),
            ),
          ),
        ),

        // ── 服务器 ──
        SliverToBoxAdapter(
          child: _SettingsSection(
            title: '服务器',
            padding: pad,
            children: [
              _SettingsTile(
                icon: Icons.dns_rounded,
                label: '服务器名称',
                value: serverName,
              ),
              _SettingsTile(
                icon: Icons.link_rounded,
                label: '服务器地址',
                value: serverUrl,
              ),
              _SettingsTile(
                icon: Icons.person_rounded,
                label: '用户名',
                value: userName,
              ),
            ],
          ),
        ),

        // ── 语言 ──
        SliverToBoxAdapter(
          child: _SettingsSection(
            title: '外观',
            padding: pad,
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                label: '中文',
                trailing: locale == AppLocale.zhCn
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.celestialCyan, size: 20)
                    : null,
                onTap: () =>
                    ref.read(localeProvider.notifier).setLocale(AppLocale.zhCn),
              ),
              _SettingsTile(
                icon: Icons.language_rounded,
                label: 'English',
                trailing: locale == AppLocale.en
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.celestialCyan, size: 20)
                    : null,
                onTap: () =>
                    ref.read(localeProvider.notifier).setLocale(AppLocale.en),
              ),
            ],
          ),
        ),

        // ── 关于 ──
        SliverToBoxAdapter(
          child: _SettingsSection(
            title: '关于',
            padding: pad,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: '版本',
                value: 'v1.0.0-dev',
              ),
              _SettingsTile(
                icon: Icons.code_rounded,
                label: '架构',
                value: 'Flutter + Go + MPV',
              ),
            ],
          ),
        ),

        // ── 退出登录 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 48),
            child: AetherButton.ghost(
              label: t.settings.logout,
              icon: Icons.logout_rounded,
              width: double.infinity,
              onPressed: () => _confirmLogout(context, ref),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.settings.logout),
        content: Text(t.settings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const ServerSelectionScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.settings.logout),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  _SettingsSection — 毛玻璃分区
// ══════════════════════════════════════════════════
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double padding;

  const _SettingsSection({
    required this.title,
    required this.children,
    this.padding = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 28, padding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分区标题
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 卡片
          AetherCard.simple(
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: AppColors.borderSubtle,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  _SettingsTile — 设置行
// ══════════════════════════════════════════════════
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
