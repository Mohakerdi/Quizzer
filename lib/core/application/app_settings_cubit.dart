import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:adv_basics/core/application/app_settings_state.dart';
import 'package:adv_basics/core/data/app_settings_local_data_source.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit({
    required AppSettingsLocalDataSource localDataSource,
  })  : _localDataSource = localDataSource,
        super(const AppSettingsState.initial());

  final AppSettingsLocalDataSource _localDataSource;

  Future<void> loadSettings() async {
    final locale = await _localDataSource.getLocale();
    final themeMode = await _localDataSource.getThemeMode();
    final arabicTutorialSeen = await _localDataSource.getArabicTutorialSeen();
    emit(
      state.copyWith(
        locale: locale,
        themeMode: themeMode,
        arabicTutorialSeen: arabicTutorialSeen,
      ),
    );
  }

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
    unawaited(_localDataSource.setLocale(locale));
  }

  void toggleThemeMode() {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: next));
    unawaited(_localDataSource.setThemeMode(next));
  }

  Future<bool> showArabicTutorialIfNeeded() async {
    if (state.arabicTutorialSeen) {
      return false;
    }
    final alreadySeen = await _localDataSource.getArabicTutorialSeen();
    if (alreadySeen) {
      emit(state.copyWith(arabicTutorialSeen: true));
      return false;
    }
    await _localDataSource.setArabicTutorialSeen(true);
    emit(state.copyWith(arabicTutorialSeen: true));
    return true;
  }
}
