
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  ThemeProvider() {
    // Synchronously load theme from SharedPreferences if possible
    SharedPreferences.getInstance().then((prefs) {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      notifyListeners();
    });
  }

  void toggleTheme(bool value) async {
    _isDarkTheme = value;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', value);
    notifyListeners();
  }
}
