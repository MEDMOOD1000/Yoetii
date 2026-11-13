import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mornye/models/theme_settings.dart';
import 'package:mornye/providers/theme_provider.dart';
import 'package:mornye/screens/settings/appearance_settings_page.dart';

class YoetiSettingsTab extends ConsumerWidget {
  const YoetiSettingsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final style = ref.watch(themeProvider).style;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            Text(
              'Settings',
              style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Make Yoeti feel like yours.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 26),
            Text(
              'Appearance',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Material(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  for (final choice in AppThemeStyle.values)
                    RadioListTile<AppThemeStyle>(
                      title: Text(
                        choice == AppThemeStyle.mornye
                            ? 'Mornye Beta'
                            : 'Material Design 3',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        choice == AppThemeStyle.mornye
                            ? 'Apple-style navigation and glass'
                            : 'Google style and color',
                      ),
                      secondary: Icon(
                        choice == AppThemeStyle.mornye
                            ? Icons.blur_on_rounded
                            : Icons.palette_outlined,
                      ),
                      value: choice,
                      groupValue: style,
                      onChanged: (value) {
                        if (value != null)
                          ref.read(themeProvider.notifier).setStyle(value);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: scheme.surfaceContainerLow,
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                leading: Icon(Icons.tune_rounded, color: scheme.primary),
                title: const Text(
                  'Colors, fonts and effects',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Open the original appearance controls'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AppearanceSettingsPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Plans repeat each week on the same weekday. Edit a block on any day to update that weekday’s plan.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
