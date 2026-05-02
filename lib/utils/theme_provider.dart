import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'is_dark_mode';

  bool _isDark;
  final SharedPreferences _prefs;

  ThemeProvider(this._prefs) : _isDark = _prefs.getBool(_key) ?? false;

  bool      get isDark     => _isDark;
  ThemeMode get themeMode  => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark;
    _prefs.setBool(_key, _isDark);
    notifyListeners();
  }
}