// ============================================================
// lib/services/gemini_service.dart
// Dil modelleri ve çeviri sonuç sınıfları.
// Çeviri artık TranslationApiService üzerinden yapılıyor.
// ============================================================

import '../models/service_result.dart';
import '../utils/app_logger.dart';

// ---- Desteklenen Diller ---- //

enum AppLanguage {
  arabic(code: 'ar', label: 'العربية', bcp47: 'ar-SA', flag: '🇸🇦'),
  english(code: 'en', label: 'English', bcp47: 'en-US', flag: '🇺🇸'),
  turkish(code: 'tr', label: 'Türkçe', bcp47: 'tr-TR', flag: '🇹🇷'),
  german(code: 'de', label: 'Deutsch', bcp47: 'de-DE', flag: '🇩🇪'),
  french(code: 'fr', label: 'Français', bcp47: 'fr-FR', flag: '🇫🇷'),
  spanish(code: 'es', label: 'Español', bcp47: 'es-ES', flag: '🇪🇸'),
  russian(code: 'ru', label: 'Русский', bcp47: 'ru-RU', flag: '🇷🇺'),
  chinese(code: 'zh', label: '中文', bcp47: 'zh-CN', flag: '🇨🇳'),
  japanese(code: 'ja', label: '日本語', bcp47: 'ja-JP', flag: '🇯🇵');

  const AppLanguage({
    required this.code,
    required this.label,
    required this.bcp47,
    required this.flag,
  });

  final String code;
  final String label;
  final String bcp47;
  final String flag;

  String get displayName => '$flag $label';
}

// ---- Çeviri Sonucu ---- //

class TranslationResult {
  final String originalText;
  final String translatedText;
  final AppLanguage sourceLanguage;
  final AppLanguage targetLanguage;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });
}