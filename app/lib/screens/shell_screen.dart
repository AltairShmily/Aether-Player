import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/search_overlay.dart';
import '../widgets/aether_page_route.dart';
import '../widgets/noise_texture.dart';
import '../widgets/server_switcher.dart';
import '../widgets/settings_modal.dart';
import 'home_tab.dart';
import 'tv_home_screen.dart';
import 'phone_library_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    HomeTab(),
    PhoneLibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final authState = ref.watch(authProvider);
    final serverName = authState.authResult?.server.serverName ?? '';
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    void openSearch() => SearchOverlay.show(context);

    Widget buildKeyboardShortcuts(Widget child) {
      return KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyK &&
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
          body: Stack(
            children: [
              _tabs[_selectedIndex.clamp(0, _tabs.length - 1)],
              const Positioned.fill(child: NoiseTexture()),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex.clamp(0, 3),
            onDestinationSelected: (i) {
              if (i == 2) {
                SearchOverlay.show(context);
              } else if (i == 3) {
                SettingsModal.show(context);
              } else {
                setState(() {
                  _selectedIndex = i;
                });
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: t.home.title,
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view),
                label: '媒体库',
              ),
              NavigationDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: const Icon(Icons.search),
                label: '搜索',
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
        body: Stack(
          children: [
            Row(
              children: [
                // ── Custom Sidebar ──
                _Sidebar(
                  selectedIndex: _selectedIndex,
                  serverName: serverName,
                  homeLabel: t.home.title,
                  settingsLabel: t.settings.title,
                  onTabSelected: (i) => setState(() {
                    _selectedIndex = i;
                  }),
                  onSearch: openSearch,
                  onTvMode: () {
                    Navigator.of(context).push(
                      AetherPageRoute(page: const TvHomeScreen(), type: AetherTransitionType.fadeScale),
                    );
                  },
                  onLibrarySelected: (libId) {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                // ── Main Content ──
                Expanded(
                  child: _tabs[_selectedIndex.clamp(0, _tabs.length - 1)],
                ),
              ],
            ),
            const Positioned.fill(child: NoiseTexture()),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Custom Sidebar — StreamVault-inspired, Aether color system
// ════════════════════════════════════════════════════════════════
class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.serverName,
    required this.homeLabel,
    required this.settingsLabel,
    required this.onTabSelected,
    this.onSearch,
    this.onTvMode,
    this.onLibrarySelected,
  });

  final int selectedIndex;
  final String serverName;
  final String homeLabel;
  final String settingsLabel;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSearch;
  final VoidCallback? onTvMode;
  final ValueChanged<String>? onLibrarySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

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
          const SizedBox(height: 20),

          // ── Home Button ──
          _SidebarButton(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: homeLabel,
            isActive: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),

          // ── Divider ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),

          // ── Library Buttons ──
          for (final lib in homeState.libraries)
            _SidebarButton(
              icon: _iconForLibraryType(lib.collectionType),
              activeIcon: _iconForLibraryType(lib.collectionType),
              label: lib.name,
              isActive: false,
              iconColor: _colorForLibraryType(lib.collectionType),
              onTap: () => onLibrarySelected?.call(lib.id),
            ),

          const SizedBox(height: 4),

          // ── Search Button ──
          _SidebarButton(
            icon: Icons.search,
            activeIcon: Icons.search,
            label: '搜索',
            isActive: false,
            onTap: onSearch ?? () {},
          ),

          // ── TV Mode Button ──
          _SidebarButton(
            icon: Icons.tv_outlined,
            activeIcon: Icons.tv,
            label: 'TV模式',
            isActive: false,
            onTap: onTvMode ?? () {},
          ),

          const Spacer(),

          // ── Bottom Section ──
          // Server Switcher
          const ServerSwitcher(),
          const SizedBox(height: 12),

          _SidebarButton(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: settingsLabel,
            isActive: false,
            onTap: () => SettingsModal.show(context),
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

  IconData _iconForLibraryType(String type) {
    switch (type) {
      case 'movies':
        return Icons.movie_outlined;
      case 'tvshows':
        return Icons.tv_outlined;
      case 'music':
        return Icons.music_note_outlined;
      default:
        return Icons.video_library_outlined;
    }
  }

  Color _colorForLibraryType(String type) {
    switch (type) {
      case 'movies':
        return AppColors.auroraGreen;
      case 'tvshows':
        return AppColors.novaPurple;
      case 'music':
        return AppColors.plasmaPink;
      default:
        return AppColors.celestialCyan;
    }
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
    this.iconColor,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? iconColor;

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
    if (widget.iconColor != null) {
      iconColor = widget.iconColor!;
    } else if (isActive) {
      iconColor = AppColors.celestialCyan;
    } else if (isHovered) {
      iconColor = AppColors.textSecondary;
    } else {
      iconColor = AppColors.textTertiary;
    }

    Color? bgColor;
    if (isActive) {
      bgColor = const Color(0x1A00D4FF);
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
