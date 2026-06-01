import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppSettingsLocalDataSource {
  Future<bool> getArabicTutorialSeen();
  Future<void> setArabicTutorialSeen(bool value);
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode value);
  Future<Locale> getLocale();
  Future<void> setLocale(Locale value);
}

class SharedPreferencesAppSettingsLocalDataSource implements AppSettingsLocalDataSource {
  const SharedPreferencesAppSettingsLocalDataSource();

  static const _tutorialSeenKey = 'quizzer_arabic_tutorial_seen_v1';
  static const _themeModeKey = 'quizzer_theme_mode_v1';
  static const _localeCodeKey = 'quizzer_locale_code_v1';

  @override
  Future<bool> getArabicTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialSeenKey) ?? false;
  }

  @override
  Future<void> setArabicTutorialSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenKey, value);
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    return value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Future<void> setThemeMode(ThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = value == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_themeModeKey, raw);
  }

  @override
  Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeCodeKey) ?? 'en';
    return Locale(code);
  }

  @override
  Future<void> setLocale(Locale value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeCodeKey, value.languageCode);
  }
}
