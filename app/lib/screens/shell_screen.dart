import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/search_overlay.dart';
import 'home_tab.dart';
import 'settings_tab.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    HomeTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final authState = ref.watch(authProvider);
    final serverName = authState.authResult?.server.serverName ?? '';
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    void openSearch() => SearchOverlay.show(context);

    Widget buildKeyboardShortcuts(Widget child) {
      return RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.key == LogicalKeyboardKey.keyK &&
              (HardwareKeyboard.instance.isControlPressed ||
               HardwareKeyboard.instance.isMetaPressed)) {
            openSearch();
          }
        },
        child: child,
      );
    }

    if (isCompact) {
      return buildKeyboardShortcuts(
        Scaffold(
          body: _tabs[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: t.home.title,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: t.settings.title,
              ),
            ],
          ),
        ),
      );
    }

    return buildKeyboardShortcuts(
      Scaffold(
        body: Row(
          children: [
            // ── Custom Sidebar ──
            _Sidebar(
              selectedIndex: _selectedIndex,
              serverName: serverName,
              homeLabel: t.home.title,
              settingsLabel: t.settings.title,
              onTabSelected: (i) => setState(() => _selectedIndex = i),
              onSearch: openSearch,
            ),
            // ── Main Content ──
            Expanded(
              child: _tabs[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Custom Sidebar — StreamVault-inspired, Aether color system
// ════════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.serverName,
    required this.homeLabel,
    required this.settingsLabel,
    required this.onTabSelected,
    this.onSearch,
  });

  final int selectedIndex;
  final String serverName;
  final String homeLabel;
  final String settingsLabel;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.nebulaDark,
        border: Border(
          right: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Logo ──
          const SizedBox(height: 16),
          _buildLogo(),
          const SizedBox(height: 24),

          // ── Navigation Buttons ──
          _SidebarButton(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: homeLabel,
            isActive: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),

          // ── Search Button ──
          _SidebarButton(
            icon: Icons.search,
            activeIcon: Icons.search,
            label: 'Search',
            isActive: false,
            onTap: onSearch ?? () {},
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(
              height: 1,
              color: AppColors.borderSubtle,
            ),
          ),

          // ── Bottom Section (spacer + settings + avatar) ──
          const Spacer(),

          // Server Avatar
          _buildServerAvatar(serverName),
          const SizedBox(height: 12),

          _SidebarButton(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: settingsLabel,
            isActive: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.deepVoid,
        size: 20,
      ),
    );
  }

  Widget _buildServerAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Tooltip(
      message: name.isNotEmpty ? name : 'Server',
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
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Sidebar Navigation Button
// ════════════════════════════════════════════════════════════════
class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final isHovered = _isHovered;

    Color iconColor;
    if (isActive) {
      iconColor = AppColors.celestialCyan;
    } else if (isHovered) {
      iconColor = AppColors.textSecondary;
    } else {
      iconColor = AppColors.textTertiary;
    }

    Color? bgColor;
    if (isActive) {
      bgColor = const Color(0x1A00D4FF); // rgba(0,212,255,0.10)
    } else if (isHovered) {
      bgColor = AppColors.surfaceHover;
    }

    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(
              isActive ? widget.activeIcon : widget.icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
