// ============================================================
// lib/config/env.dart
//
// ⚠️  COMMON MISTAKE: Hardcoding API keys in source files.
//     That gets committed to Git → anyone who clones the repo
//     owns your Gemini quota and billing account.
//
// CORRECT APPROACH (used here):
//   1. Keys live in a .env file at project root (git-ignored).
//   2. flutter_dotenv loads them at runtime.
//   3. This class is the single access point — nowhere else
//      in the codebase touches String literals for secrets.
//
// HOW TO SET UP:
//   a) Add to pubspec.yaml:
//        dependencies:
//          flutter_dotenv: ^5.1.0
//      assets:
//        - .env
//   b) Create .env at project root:
//        GEMINI_API_KEY=AIza...yourkey...
//   c) Add .env to .gitignore (CRITICAL).
//   d) Call Env.init() inside main() before runApp().
// ============================================================

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  /// Call once in main() — await Env.init();
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  /// Gemini API key. Throws a clear error if not configured.
  static String get geminiApiKey {
    final key = dotenv.maybeGet('GEMINI_API_KEY');
    if (key == null || key.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is missing from your .env file.\n'
        'Create a .env file at the project root and add:\n'
        '  GEMINI_API_KEY=your_key_here\n'
        'Then add .env to .gitignore.',
      );
    }
    return key;
  }

  /// Gemini REST endpoint — only change this if Google updates the URL.
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Max milliseconds to wait for the Gemini API before giving up.
  static const Duration geminiTimeout = Duration(seconds: 15);

  /// How many times to retry a failed API call before reporting failure.
  static const int geminiMaxRetries = 2;
}