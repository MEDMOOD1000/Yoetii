import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mornye/app.dart';
import 'package:mornye/providers/settings_provider.dart';
import 'package:mornye/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      initialSettingsProvider.overrideWithValue(loadBootstrapSettings(prefs)),
      initialThemeSettingsProvider.overrideWithValue(loadBootstrapThemeSettings(prefs)),
    ],
    child: const MornyeApp(),
  ));
}
