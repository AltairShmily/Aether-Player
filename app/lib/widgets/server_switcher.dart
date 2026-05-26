import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/saved_servers_provider.dart';
import '../screens/server_selection_screen.dart';
import '../widgets/aether_page_route.dart';

/// 服务器/账号切换器 — 侧边栏底部下拉菜单
///
/// 使用 PopupMenuButton 实现可靠的下拉菜单
class ServerSwitcher extends ConsumerWidget {
  const ServerSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final serverName = authState.authResult?.server.serverName ?? '';
    final initial = serverName.isNotEmpty ? serverName[0].toUpperCase() : '?';

    return PopupMenuButton<String>(
      offset: const Offset(48, 0),
      onSelected: (value) {
        if (value == 'add_account') {
          Navigator.of(context).push(
            AetherPageRoute(
              page: const ServerSelectionScreen(),
              type: AetherTransitionType.fadeSlide,
            ),
          );
        }
      },
      itemBuilder: (context) {
        final savedServers = ref.read(savedServersProvider);
        final currentServerName = authState.authResult?.server.serverName ?? '';
        final currentUserName = authState.authResult?.user.name ?? '';

        return [
          // 服务器标签
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              '服务器',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          // 当前服务器
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.auroraGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.auroraGreen.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentServerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.celestialCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 其他保存的服务器
          ...savedServers
              .where((s) => s.serverName != currentServerName)
              .map((s) => PopupMenuItem<String>(
                    enabled: false,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.serverName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                s.serverUrl,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontFamily: 'DM Mono',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          const PopupMenuDivider(),
          // 账号标签
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              '账号',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          // 当前账号
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                  ),
                  child: Center(
                    child: Text(
                      currentUserName.isNotEmpty ? currentUserName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUserName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.celestialCyan,
                        ),
                      ),
                      const Text(
                        '管理员',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // 添加账号
          const PopupMenuItem<String>(
            value: 'add_account',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_outlined, size: 18, color: AppColors.textTertiary),
                SizedBox(width: 8),
                Text(
                  '添加账号',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ];
      },
      child: Tooltip(
        message: '服务器与账号',
        waitDuration: const Duration(milliseconds: 400),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.celestialCyan, AppColors.novaPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
