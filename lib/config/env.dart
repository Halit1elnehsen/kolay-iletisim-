// ============================================================
// lib/config/env.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  // API key من --dart-define وقت البناء
  static const String _compiledKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static Future<void> init() async {
    // بالـ development فقط نحمّل الـ .env
    if (kDebugMode && _compiledKey.isEmpty) {
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {}
    }
  }

  static String get geminiApiKey {
    // أولاً: من --dart-define (APK release)
    if (_compiledKey.isNotEmpty) return _compiledKey;

    // ثانياً: من .env (development)
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_GEMINI_API_KEY_HERE') {
      throw StateError('GEMINI_API_KEY غير موجود!');
    }
    return key;
  }

  static const Duration geminiTimeout = Duration(seconds: 15);
  static const int geminiMaxRetries = 2;
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
}