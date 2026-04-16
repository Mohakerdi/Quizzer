import 'package:shared_preferences/shared_preferences.dart';

abstract class AppSettingsLocalDataSource {
  Future<bool> getArabicTutorialSeen();
  Future<void> setArabicTutorialSeen(bool value);
}

class SharedPreferencesAppSettingsLocalDataSource implements AppSettingsLocalDataSource {
  const SharedPreferencesAppSettingsLocalDataSource();

  static const _tutorialSeenKey = 'quizzer_arabic_tutorial_seen_v1';

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
}
