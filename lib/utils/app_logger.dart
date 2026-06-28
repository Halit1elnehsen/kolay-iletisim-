// ============================================================
// lib/utils/app_logger.dart
// Production-ready loglama — debug'da verbose, release'de sessiz.
// ============================================================

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void w(String tag, String message) =>
      _log(LogLevel.warning, tag, message);

  static void e(String tag, String message, [Object? error]) {
    _log(LogLevel.error, tag, message);
    if (error != null && kDebugMode) {
      debugPrint('  ERROR DETAIL: $error');
    }
  }

  static void _log(LogLevel level, String tag, String message) {
    if (!kDebugMode) return; // Release build'de log yok

    final emoji = switch (level) {
      LogLevel.debug   => '🔵',
      LogLevel.info    => '🟢',
      LogLevel.warning => '🟡',
      LogLevel.error   => '🔴',
    };

    final time = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('$emoji [$time] [$tag] $message');
  }
}