import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adv_basics/core/application/app_settings_cubit.dart';
import 'package:adv_basics/core/data/app_settings_local_data_source.dart';

class _InMemoryAppSettingsLocalDataSource implements AppSettingsLocalDataSource {
  bool _arabicTutorialSeen = false;

  @override
  Future<bool> getArabicTutorialSeen() async => _arabicTutorialSeen;

  @override
  Future<void> setArabicTutorialSeen(bool value) async {
    _arabicTutorialSeen = value;
  }
}

void main() {
  test('AppSettingsCubit toggles theme and updates locale', () {
    final cubit = AppSettingsCubit(
      localDataSource: _InMemoryAppSettingsLocalDataSource(),
    );

    expect(cubit.state.themeMode, ThemeMode.light);
    expect(cubit.state.locale, const Locale('en'));

    cubit.toggleThemeMode();
    cubit.setLocale(const Locale('ar'));

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.locale, const Locale('ar'));
  });

  test('AppSettingsCubit marks Arabic tutorial as seen once', () async {
    final cubit = AppSettingsCubit(
      localDataSource: _InMemoryAppSettingsLocalDataSource(),
    );

    expect(await cubit.shouldShowArabicTutorial(), isTrue);
    expect(await cubit.shouldShowArabicTutorial(), isFalse);
  });
}
