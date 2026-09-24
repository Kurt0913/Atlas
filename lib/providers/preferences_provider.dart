import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  static const String _keyTheme = 'theme_preference';
  static const String _keyCurrency = 'default_currency';
  static const String _keyNotifications = 'notifications_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  String _defaultCurrency = 'PHP';
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  String get defaultCurrency => _defaultCurrency;
  bool get notificationsEnabled => _notificationsEnabled;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  PreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_keyTheme);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _defaultCurrency = prefs.getString(_keyCurrency) ?? 'PHP';
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_keyTheme, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(_keyTheme, 'light');
    } else {
      await prefs.setString(_keyTheme, 'system');
    }
  }

  Future<void> setDefaultCurrency(String currency) async {
    _defaultCurrency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
  }
}
