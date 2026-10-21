import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.system,
  });

  final Locale locale;
  final ThemeMode themeMode;

  SettingsState copyWith({Locale? locale, ThemeMode? themeMode}) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [locale.languageCode, themeMode];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(const SettingsState()) {
    final lang = _prefs.getString(_langKey) ?? 'en';
    final theme = _prefs.getString(_themeKey) ?? 'system';
    emit(
      SettingsState(
        locale: Locale(lang),
        themeMode: switch (theme) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => ThemeMode.system,
        },
      ),
    );
  }

  static const _langKey = 'badrgo_lang';
  static const _themeKey = 'badrgo_theme';

  final SharedPreferences _prefs;

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_langKey, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  Future<void> toggleLocale() async {
    final next = state.locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeKey, value);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> cycleTheme() async {
    final next = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }
}
