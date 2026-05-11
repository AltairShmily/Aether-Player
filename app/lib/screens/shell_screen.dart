import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/strings.g.dart';
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
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    final destinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: Text(t.home.title),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: Text(t.settings.title),
      ),
    ];

    if (isCompact) {
      return Scaffold(
        body: _tabs[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: destinations.map((d) => NavigationDestination(
            icon: d.icon,
            selectedIcon: d.selectedIcon,
            label: (d.label as Text).data!,
          )).toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: Icon(
                      _selectedIndex == 1 ? Icons.settings : Icons.settings_outlined,
                      color: _selectedIndex == 1
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () => setState(() => _selectedIndex = 1),
                    tooltip: t.settings.title,
                  ),
                ),
              ),
            ),
            destinations: destinations,
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          Expanded(
            child: _tabs[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
