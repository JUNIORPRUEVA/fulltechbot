import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_config.dart';

class AdminSessionService {
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConfig.adminSessionStorageKey) ?? false;
  }

  static Future<void> setAuthenticated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.adminSessionStorageKey, value);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.adminSessionStorageKey);
  }
}
