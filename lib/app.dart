import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:mornye/l10n/app_localizations.dart';
import 'package:mornye/l10n/supported_locales.dart';
import 'package:mornye/providers/settings_provider.dart';
import 'package:mornye/screens/main_shell.dart';
import 'package:mornye/theme/dynamic_color_wrapper.dart';
import 'package:mornye/utils/adaptive_layout.dart';
import 'package:mornye/widgets/app_snack_bar.dart';
import 'package:mornye/widgets/mornye_glass_preparation.dart';

/// Shared theme and navigation host. Feature content belongs to the tabs.
class MornyeApp extends ConsumerWidget {
  const MornyeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = localeFromSetting(
      ref.watch(settingsProvider.select((settings) => settings.locale)),
    );
    return DynamicColorWrapper(
      builder: (lightTheme, darkTheme, themeMode) => MaterialApp(
        title: 'Mornye',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        themeAnimationDuration: const Duration(milliseconds: 300),
        themeAnimationCurve: Curves.easeInOut,
        locale: locale,
        localeResolutionCallback: (deviceLocale, supported) =>
            resolveSupportedLocale(locale ?? deviceLocale, supported),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          material_ui.GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: filteredSupportedLocales,
        builder: (context, child) => MornyeGlassPreparation(
          child: AdaptiveUiScaler(
            child: AppScaffoldMessenger(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
        home: const MainShell(),
      ),
    );
  }
}
