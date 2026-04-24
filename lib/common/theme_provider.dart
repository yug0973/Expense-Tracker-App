import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme';

  bool _isDark = true;

  bool get isDark => _isDark;

  /// Returns "Dark" or "Light" — used by SettingsView to show current value.
  String get currentLabel => _isDark ? 'Dark' : 'Light';

  /// Load persisted preference on app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = (prefs.getString(_key) ?? 'Dark') == 'Dark';
    notifyListeners();
  }

  /// Same API as before — called from SettingsView with "Dark" or "Light".
  Future<void> toggleTheme(String selected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, selected);
    _isDark = selected == 'Dark';
    notifyListeners();
  }
}