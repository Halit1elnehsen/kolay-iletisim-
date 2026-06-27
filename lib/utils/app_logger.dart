// ============================================================
// lib/utils/app_logger.dart
// Centralized logger — replace print() calls with this.
// In production builds, swap the body for a crash-reporting
// SDK (e.g. Firebase Crashlytics) without touching any other file.
// ============================================================

import 'package:flutter/foundation.dart';

/// Log levels — ordered by severity.
enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._(); // prevent instantiation

  static const String _reset  = '\x1B[0m';
  static const String _cyan   = '\x1B[36m';
  static const String _yellow = '\x1B[33m';
  static const String _red    = '\x1B[31m';
  static const String _grey   = '\x1B[90m';

  static void debug(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void info(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void warning(String tag, String message) =>
      _log(LogLevel.warning, tag, message);

  static void error(String tag, String message, [Object? exception, StackTrace? stack]) {
    _log(LogLevel.error, tag, message);
    if (exception != null) _log(LogLevel.error, tag, 'Exception: $exception');
    if (stack    != null) _log(LogLevel.error, tag, 'Stack:\n$stack');
  }

  static void _log(LogLevel level, String tag, String message) {
    // Only emit logs in debug mode — zero overhead in release builds.
    if (!kDebugMode) return;

    final now    = DateTime.now();
    final time   = '${now.hour.toString().padLeft(2,'0')}:'
                   '${now.minute.toString().padLeft(2,'0')}:'
                   '${now.second.toString().padLeft(2,'0')}';

    final (color, icon) = switch (level) {
      LogLevel.debug   => (_grey,   '🔍'),
      LogLevel.info    => (_cyan,   'ℹ️ '),
      LogLevel.warning => (_yellow, '⚠️ '),
      LogLevel.error   => (_red,    '🔴'),
    };

    // ignore: avoid_print
    print('$color$icon [$time][$tag] $message$_reset');
  }
}