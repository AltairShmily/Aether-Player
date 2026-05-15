import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../providers/saved_servers_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/aether_card.dart';
import '../widgets/aether_button.dart';
import 'login_screen.dart';
import 'shell_screen.dart';

class ServerSelectionScreen extends ConsumerStatefulWidget {
  const ServerSelectionScreen({super.key});

  @override
  ConsumerState<ServerSelectionScreen> createState() =>
      _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends ConsumerState<ServerSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _starController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedServersProvider.notifier).load();
      _tryAutoLogin();
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoLogin() async {
    final success = await ref.read(authProvider.notifier).tryAutoLogin();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen()),
      );
    }
  }

  Future<void> _loginToServer(dynamic server) async {
    final success = await ref.read(authProvider.notifier).loginFromSaved(server);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final savedServers = ref.watch(savedServersProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Stack(
        children: [
          // ── 星空粒子背景 ──
          AnimatedBuilder(
            animation: _starController,
            builder: (context, _) => CustomPaint(
              painter: _StarPainter(
                animation: _starController.value,
              ),
              size: Size.infinite,
            ),
          ),

          // ── 径向光晕 ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 0.8,
                  colors: [
                    AppColors.celestialCyan.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── 内容 ──
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // ── Logo ──
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.celestialCyan.withValues(alpha: 0.3),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.deepVoid,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 标题 ──
                      const Text(
                        'AETHER',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.serverSelection.subtitle,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── 服务器列表 / 加载态 ──
                      if (authState.isLoading)
                        const CircularProgressIndicator(
                          color: AppColors.celestialCyan,
                          strokeWidth: 2,
                        )
                      else if (savedServers.isEmpty)
                        // 空状态
                        Column(
                          children: [
                            Icon(
                              Icons.dns_outlined,
                              size: 48,
                              color: AppColors.cosmicGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t.serverSelection.title,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      else
                        // 服务器卡片列表
                        Expanded(
                          child: ListView.separated(
                            itemCount: savedServers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final server = savedServers[index];
                              return _ServerItemCard(
                                server: server,
                                onTap: () => _loginToServer(server),
                                onDelete: () => _confirmDelete(server),
                              );
                            },
                          ),
                        ),

                      // ── 错误信息 ──
                      if (authState.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── 添加服务器按钮 ──
                      AetherButton.primary(
                        label: t.serverSelection.addNew,
                        icon: Icons.add_rounded,
                        width: double.infinity,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                      ),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic server) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.serverSelection.deleteServer),
        content: Text(
            t.serverSelection.deleteConfirm(serverName: server.serverName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(savedServersProvider.notifier).removeServer(server.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  _ServerItemCard — 服务器卡片
// ══════════════════════════════════════════════════
class _ServerItemCard extends StatelessWidget {
  final dynamic server;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ServerItemCard({
    required this.server,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AetherCard.simple(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.celestialCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dns_rounded,
              color: AppColors.celestialCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.serverName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  server.serverUrl,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'JetBrains Mono',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  _StarPainter — 星空粒子绘制
// ══════════════════════════════════════════════════
class _StarPainter extends CustomPainter {
  final double animation;
  final List<_Star> _stars;

  _StarPainter({required this.animation})
      : _stars = List.generate(80, (i) => _Star.random(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle = (sin(animation * 2 * pi + star.phase) + 1) / 2;
      final opacity = 0.15 + twinkle * 0.35;
      final paint = Paint()
        ..color = star.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.blur);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.animation != animation;
}

class _Star {
  final double x, y, radius, phase, blur;
  final Color color;

  _Star(this.x, this.y, this.radius, this.phase, this.blur, this.color);

  factory _Star.random(int seed) {
    final r = Random(seed);
    final colors = [
      AppColors.celestialCyan,
      AppColors.novaPurple,
      AppColors.auroraGreen,
      Colors.white,
    ];
    return _Star(
      r.nextDouble(),
      r.nextDouble(),
      0.5 + r.nextDouble() * 1.5,
      r.nextDouble() * 2 * pi,
      0.3 + r.nextDouble() * 0.7,
      colors[r.nextInt(colors.length)],
    );
  }
}
