import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mornye/l10n/l10n.dart';
import 'package:mornye/screens/empty_content.dart';
import 'package:mornye/screens/settings/appearance_settings_page.dart';
import 'package:mornye/theme/mornye_theme.dart';
import 'package:mornye/widgets/expressive_navigation_bar.dart';
import 'package:mornye/widgets/mornye_bottom_bar.dart';

/// The original Mornye themes and navigation chrome around reusable content slots.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _home = 0;
  static const _workspace = 1;
  static const _search = 2;
  static const _settings = 3;
  late final PageController _pages = PageController();
  int _selected = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mornye = context.isMornye;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: Icon(mornye ? CupertinoIcons.house_fill : Icons.home_outlined),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: Icon(
          mornye ? CupertinoIcons.square_stack_fill : Icons.dashboard_outlined,
        ),
        label: l10n.navLibrary,
      ),
      NavigationDestination(
        icon: Icon(mornye ? CupertinoIcons.search : Icons.search),
        label: l10n.mornyeSearch,
      ),
      NavigationDestination(
        icon: Icon(mornye ? CupertinoIcons.gear_alt : Icons.settings_outlined),
        label: l10n.navSettings,
      ),
    ];
    final pageView = PageView(
      controller: _pages,
      onPageChanged: (index) => setState(() => _selected = index),
      children: [
        EmptyContent(title: l10n.navHome),
        EmptyContent(title: l10n.navLibrary),
        EmptyContent(title: l10n.mornyeSearch),
        const AppearanceSettingsPage(),
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selected,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final item in destinations)
                        NavigationRailDestination(
                          icon: item.icon,
                          label: Text(item.label),
                        ),
                    ],
                  ),
                  Expanded(child: pageView),
                ],
              )
            : pageView,
      ),
      bottomNavigationBar: wide
          ? null
          : SafeArea(
              top: false,
              child: mornye
                  ? MornyeBottomBar(
                      collapsed: false,
                      destinations: destinations,
                      searchIndex: _search,
                      selectedIndex: _selected,
                      onSelected: _select,
                      onHome: () => _select(_home),
                      onSearch: () => _select(_search),
                      blurEnabled: true,
                    )
                  : ExpressiveNavigationBar(
                      selectedIndex: _selected,
                      onDestinationSelected: _select,
                      destinations: destinations,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      isTablet: MediaQuery.sizeOf(context).shortestSide >= 600,
                    ),
            ),
    );
  }
}
