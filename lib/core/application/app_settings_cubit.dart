import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adv_basics/core/application/app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  static const _tutorialSeenKey = 'quizzer_arabic_tutorial_seen_v1';

  AppSettingsCubit() : super(const AppSettingsState.initial());

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }

  void toggleThemeMode() {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: next));
  }

  Future<bool> shouldShowArabicTutorial() async {
    if (state.arabicTutorialSeen) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool(_tutorialSeenKey) ?? false;
    if (alreadySeen) {
      emit(state.copyWith(arabicTutorialSeen: true));
      return false;
    }
    await prefs.setBool(_tutorialSeenKey, true);
    emit(state.copyWith(arabicTutorialSeen: true));
    return true;
  }
}
