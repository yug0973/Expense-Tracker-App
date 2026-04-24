import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  static const _keyName = 'user_name';
  static const _keyEmail = 'user_email';

  String _name = '';
  String _email = '';

  String get name => _name;

  String get email => _email;

  UserProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_keyName) ?? '';
    _email = prefs.getString(_keyEmail) ?? '';
    notifyListeners();
  }

  Future<void> updateProfile(
      {required String name, required String email}) async {
    _name = name;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    notifyListeners();
  }

  Future<void> clear() async {
    _name = '';
    _email = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    notifyListeners();
  }
}