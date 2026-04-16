import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({
    required this.locale,
    required this.themeMode,
    required this.arabicTutorialSeen,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final bool arabicTutorialSeen;

  const AppSettingsState.initial()
      : locale = const Locale('en'),
        themeMode = ThemeMode.light,
        arabicTutorialSeen = false;

  AppSettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? arabicTutorialSeen,
  }) {
    return AppSettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      arabicTutorialSeen: arabicTutorialSeen ?? this.arabicTutorialSeen,
    );
  }

  @override
  List<Object?> get props => [locale, themeMode, arabicTutorialSeen];
}
