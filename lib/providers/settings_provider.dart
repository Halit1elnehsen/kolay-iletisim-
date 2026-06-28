// ============================================================
// lib/providers/settings_provider.dart
// Kullanıcı ayarları — tema, varsayılan dil, TTS hızı vb.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _defaultSource = AppLanguage.arabic;
  AppLanguage _defaultTarget = AppLanguage.turkish;
  double _speechRate = 0.45;
  bool _autoSpeak = true;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get defaultSource => _defaultSource;
  AppLanguage get defaultTarget => _defaultTarget;
  double get speechRate => _speechRate;
  bool get autoSpeak => _autoSpeak;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString('themeMode') ?? 'system';
    _themeMode = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };

    final srcCode = prefs.getString('defaultSource') ?? 'ar';
    final tgtCode = prefs.getString('defaultTarget') ?? 'tr';
    _defaultSource = AppLanguage.values.firstWhere(
      (l) => l.code == srcCode, orElse: () => AppLanguage.arabic);
    _defaultTarget = AppLanguage.values.firstWhere(
      (l) => l.code == tgtCode, orElse: () => AppLanguage.turkish);

    _speechRate = prefs.getDouble('speechRate') ?? 0.45;
    _autoSpeak = prefs.getBool('autoSpeak') ?? true;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', switch (mode) {
      ThemeMode.light  => 'light',
      ThemeMode.dark   => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }

  Future<void> setDefaultSource(AppLanguage lang) async {
    _defaultSource = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultSource', lang.code);
    notifyListeners();
  }

  Future<void> setDefaultTarget(AppLanguage lang) async {
    _defaultTarget = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultTarget', lang.code);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speechRate', rate);
    notifyListeners();
  }

  Future<void> setAutoSpeak(bool value) async {
    _autoSpeak = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSpeak', value);
    notifyListeners();
  }
}
