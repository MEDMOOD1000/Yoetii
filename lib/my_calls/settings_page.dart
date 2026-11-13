import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mornye/models/theme_settings.dart';
import 'package:mornye/providers/theme_provider.dart';
import 'package:mornye/screens/settings/appearance_settings_page.dart';

import 'store.dart';

class CallsSettingsPage extends ConsumerWidget {
  const CallsSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(themeProvider).style;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Make My Calls yours.',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 25),
            Text(
              'THEME',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: scheme.surfaceContainerLow,
              elevation: 0,
              child: Column(
                children: [
                  for (final style in AppThemeStyle.values)
                    ListTile(
                      leading: Icon(
                        style == AppThemeStyle.mornye
                            ? Icons.blur_on_rounded
                            : Icons.palette_outlined,
                      ),
                      title: Text(
                        style == AppThemeStyle.mornye
                            ? 'Mornye Beta'
                            : 'Material Design 3',
                      ),
                      subtitle: Text(
                        style == AppThemeStyle.mornye
                            ? 'Glass and fluid tabs'
                            : 'Google color system',
                      ),
                      trailing: selected == style
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            )
                          : null,
                      onTap: () =>
                          ref.read(themeProvider.notifier).setStyle(style),
                    ),
                ],
              ),
            ),
            Card(
              color: scheme.surfaceContainerLow,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Colors, fonts and effects'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AppearanceSettingsPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'WELCOME QUOTE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: MyCallsStore.instance,
              builder: (context, _) => Card(
                color: scheme.surfaceContainerLow,
                elevation: 0,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Care notes'),
                      subtitle: const Text('Short original phrases'),
                      trailing: MyCallsStore.instance.quoteMode == 'care'
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            )
                          : null,
                      onTap: () => MyCallsStore.instance.setQuoteMode('care'),
                    ),
                    ListTile(
                      title: const Text('Quran'),
                      subtitle: const Text('Short sourced verses'),
                      trailing: MyCallsStore.instance.quoteMode == 'quran'
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            )
                          : null,
                      onTap: () => MyCallsStore.instance.setQuoteMode('quran'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Shifts and notes are stored on this device. Patient values entered in Dose math are not saved.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
