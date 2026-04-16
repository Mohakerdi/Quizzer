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

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }

  void toggleThemeMode() {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: next));
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
