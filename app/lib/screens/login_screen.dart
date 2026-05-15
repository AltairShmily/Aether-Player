import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/aether_card.dart';
import '../widgets/aether_button.dart';
import '../widgets/aether_badge.dart';
import 'shell_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isServerConnected = false;
  bool _obscurePassword = true;

  Future<void> _connectToServer() async {
    final serverUrl = _serverController.text.trim();
    if (serverUrl.isEmpty) return;

    final success =
        await ref.read(authProvider.notifier).connectToServer(serverUrl);
    if (success) {
      setState(() => _isServerConnected = true);
    }
  }

  Future<void> _login() async {
    final serverUrl = _serverController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) return;

    final success = await ref.read(authProvider.notifier).login(
          serverUrl,
          username,
          password,
        );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ShellScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Stack(
        children: [
          // ── 顶部渐变光晕 ──
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            height: 400,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.8,
                  colors: [
                    AppColors.celestialCyan.withValues(alpha: 0.08),
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
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // ── Logo + 标题 ──
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.deepVoid,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'AETHER',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '连接你的媒体服务器',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── 服务器 URL ──
                      Text(
                        '服务器地址',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _serverController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: t.login.serverUrlHint,
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.dns_outlined,
                              color: AppColors.textSecondary),
                          suffixIcon: _isServerConnected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.auroraGreen)
                              : IconButton(
                                  icon: const Icon(Icons.arrow_forward,
                                      color: AppColors.celestialCyan),
                                  onPressed: _connectToServer,
                                ),
                        ),
                        keyboardType: TextInputType.url,
                        onSubmitted: (_) => _connectToServer(),
                        enabled: !_isServerConnected,
                      ),

                      // ── 连接按钮 ──
                      if (!_isServerConnected) ...[
                        const SizedBox(height: 20),
                        AetherButton.primary(
                          label: t.common.connect,
                          icon: Icons.wifi_find_rounded,
                          width: double.infinity,
                          onPressed:
                              authState.isLoading ? null : _connectToServer,
                        ),
                      ],

                      // ── 登录表单 ──
                      if (_isServerConnected) ...[
                        const SizedBox(height: 24),

                        // 已连接服务器信息
                        if (authState.serverInfo != null)
                          AetherCard.simple(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const AetherBadge.dot(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authState.serverInfo!.serverName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'v${authState.serverInfo!.version}',
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 13,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18, color: AppColors.textSecondary),
                                  onPressed: () => setState(
                                      () => _isServerConnected = false),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // 用户名
                        Text(
                          '用户名',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            hintText: '请输入用户名',
                            prefixIcon: Icon(Icons.person_outline,
                                color: AppColors.textSecondary),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 密码
                        Text(
                          '密码',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: '请输入密码',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() =>
                                    _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),

                        const SizedBox(height: 32),

                        // 登录按钮
                        AetherButton.primary(
                          label: t.login.signIn,
                          icon: Icons.login_rounded,
                          width: double.infinity,
                          onPressed: authState.isLoading ? null : _login,
                        ),
                      ],

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

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
