import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adv_basics/core/application/app_settings_cubit.dart';

void main() {
  test('AppSettingsCubit toggles theme and updates locale', () {
    final cubit = AppSettingsCubit();

    expect(cubit.state.themeMode, ThemeMode.light);
    expect(cubit.state.locale, const Locale('en'));

    cubit.toggleThemeMode();
    cubit.setLocale(const Locale('ar'));

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.locale, const Locale('ar'));
  });
}
