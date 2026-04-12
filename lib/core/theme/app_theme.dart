import 'package:flutter/material.dart';

const _brandBlue = Color(0xFF1D57C8);
const _brandSky = Color(0xFF62CEF7);
const _brandGold = Color(0xFFFEC62F);
const _brandInk = Color(0xFF123A8B);

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _brandBlue,
    brightness: Brightness.light,
  ).copyWith(
    primary: _brandBlue,
    secondary: _brandGold,
    tertiary: _brandSky,
    surface: const Color(0xFFF7FAFF),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFEFF5FF),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: _brandInk,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: _brandInk,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 1,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _brandGold,
      foregroundColor: _brandInk,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: _brandBlue,
      labelColor: _brandBlue,
      unselectedLabelColor: Color(0xFF5573A6),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _brandBlue,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF7AA9FF),
    secondary: _brandGold,
    tertiary: const Color(0xFF7FDFFF),
    surface: const Color(0xFF111C34),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0A1328),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Color(0xFF132241),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF3E78ED),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _brandGold,
      foregroundColor: _brandInk,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: Color(0xFF7AA9FF),
      labelColor: Color(0xFF9BC0FF),
      unselectedLabelColor: Color(0xFF8CA3CF),
    ),
  );
}
