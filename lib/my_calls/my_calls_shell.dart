import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mornye/providers/runtime_profile_provider.dart';
import 'package:mornye/theme/mornye_theme.dart';
import 'package:mornye/widgets/expressive_navigation_bar.dart';
import 'package:mornye/widgets/mornye_bottom_bar.dart';

import 'dose_tab.dart';
import 'duty_tab.dart';
import 'home_tab.dart';
import 'notes_tab.dart';
import 'settings_page.dart';

class MyCallsShell extends ConsumerStatefulWidget {
  const MyCallsShell({super.key});
  @override
  ConsumerState<MyCallsShell> createState() => _MyCallsShellState();
}

class _MyCallsShellState extends ConsumerState<MyCallsShell> {
  final _pages = PageController();
  int _index = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _settings() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CallsSettingsPage()));
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mornye = context.isMornye;
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: Icon(mornye ? CupertinoIcons.house : Icons.home_outlined),
        selectedIcon: Icon(
          mornye ? CupertinoIcons.house_fill : Icons.home_rounded,
        ),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(
          mornye ? CupertinoIcons.calendar : Icons.calendar_month_outlined,
        ),
        selectedIcon: Icon(
          mornye ? CupertinoIcons.calendar : Icons.calendar_month_rounded,
        ),
        label: 'Duty',
      ),
      NavigationDestination(
        icon: Icon(
          mornye ? CupertinoIcons.plus_slash_minus : Icons.calculate_outlined,
        ),
        selectedIcon: Icon(
          mornye ? CupertinoIcons.plus_slash_minus : Icons.calculate_rounded,
        ),
        label: 'Dose',
      ),
      NavigationDestination(
        icon: Icon(
          mornye ? CupertinoIcons.square_pencil : Icons.sticky_note_2_outlined,
        ),
        selectedIcon: Icon(
          mornye ? CupertinoIcons.square_pencil : Icons.sticky_note_2_rounded,
        ),
        label: 'Notes',
      ),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pages,
            onPageChanged: (index) => setState(() => _index = index),
            children: [
              CallsHome(
                openShifts: () => _go(1),
                openDoses: () => _go(2),
                openNotes: () => _go(3),
              ),
              const DutyTab(),
              const DoseTab(),
              const NotesTab(),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 13,
            right: 18,
            child: Tooltip(
              message: 'Settings',
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Material(
                    color: scheme.surface.withValues(alpha: .66),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: .55),
                      ),
                    ),
                    child: IconButton(
                      onPressed: _settings,
                      icon: Icon(
                        mornye
                            ? CupertinoIcons.gear_alt
                            : Icons.settings_outlined,
                      ),
                      color: scheme.onSurface,
                      iconSize: 22,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: mornye
          ? SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: MornyeBottomBar(
                collapsed: false,
                destinations: destinations,
                selectedIndex: _index,
                onSelected: _go,
                onHome: () => _go(0),
                onSearch: () => _go(3),
                searchIndex: 3,
                blurEnabled: ref.watch(mornyeBlurEnabledProvider),
              ),
            )
          : ExpressiveNavigationBar(
              destinations: destinations,
              selectedIndex: _index,
              onDestinationSelected: _go,
              backgroundColor: scheme.surfaceContainer.withValues(alpha: .85),
            ),
    );
  }
}
