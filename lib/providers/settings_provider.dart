import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'empty_shell_settings';

class AppSettings {
  const AppSettings({
    this.locale = 'system',
    this.heroAnimationsEnabled = true,
    this.forceBackdropBlur = false,
    this.historyViewMode = 'grid',
  });

  final String locale;
  final bool heroAnimationsEnabled;
  final bool forceBackdropBlur;
  final String historyViewMode;

  AppSettings copyWith({
    String? locale,
    bool? heroAnimationsEnabled,
    bool? forceBackdropBlur,
    String? historyViewMode,
  }) => AppSettings(
    locale: locale ?? this.locale,
    heroAnimationsEnabled: heroAnimationsEnabled ?? this.heroAnimationsEnabled,
    forceBackdropBlur: forceBackdropBlur ?? this.forceBackdropBlur,
    historyViewMode: historyViewMode ?? this.historyViewMode,
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    locale: json['locale'] as String? ?? 'system',
    heroAnimationsEnabled: json['heroAnimationsEnabled'] as bool? ?? true,
    forceBackdropBlur: json['forceBackdropBlur'] as bool? ?? false,
    historyViewMode: json['historyViewMode'] as String? ?? 'grid',
  );

  Map<String, dynamic> toJson() => {
    'locale': locale,
    'heroAnimationsEnabled': heroAnimationsEnabled,
    'forceBackdropBlur': forceBackdropBlur,
    'historyViewMode': historyViewMode,
  };
}

AppSettings loadBootstrapSettings(SharedPreferences prefs) {
  for (final key in [_key, 'app_settings']) {
    final raw = prefs.getString(key);
    if (raw == null) continue;
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      /* Ignore corrupt old preferences. */
    }
  }
  return const AppSettings();
}

final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> setLocale(String value) async {
    state = state.copyWith(locale: value);
    await _save();
  }

  Future<void> setHeroAnimationsEnabled(bool value) async {
    state = state.copyWith(heroAnimationsEnabled: value);
    await _save();
  }

  Future<void> setForceBackdropBlur(bool value) async {
    state = state.copyWith(forceBackdropBlur: value);
    await _save();
  }

  Future<void> setHistoryViewMode(String value) async {
    state = state.copyWith(historyViewMode: value);
    await _save();
  }
}
