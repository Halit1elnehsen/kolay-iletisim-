// ============================================================
// lib/config/env.dart
// Güvenli API key yönetimi — .env dosyasından okur.
// ⚠️ Hiçbir zaman API key'i kaynak koduna yazmayın!
// ============================================================

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  /// main() içinde runApp'tan önce çağrılmalı.
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  /// Gemini API Key — .env dosyasındaki GEMINI_API_KEY değeri.
  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty || key == 'YOUR_GEMINI_API_KEY_HERE') {
      throw StateError(
        '⚠️ GEMINI_API_KEY .env dosyasında tanımlanmamış!\n'
        'Lütfen .env dosyasına şunu ekleyin:\n'
        'GEMINI_API_KEY=AIza...yourkey...',
      );
    }
    return key;
  }
}