// ============================================================
// lib/services/gemini_service.dart
// Google Gemini 1.5 Flash ile çeviri servisi.
// Singleton — tek model instance, maliyet optimizasyonu.
// ============================================================

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/env.dart';
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

// ---- Servis ---- //

class GeminiService {
  GeminiService._internal();
  static final GeminiService instance = GeminiService._internal();
  static const _tag = 'GeminiService';

  GenerativeModel? _model;

  void initialize() {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: Env.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,   // Düşük yaratıcılık — çeviri için doğruluk önemli
          maxOutputTokens: 1024,
        ),
      );
      AppLogger.i(_tag, 'Gemini 1.5 Flash hazır.');
    } catch (e) {
      AppLogger.e(_tag, 'Başlatma hatası', e);
    }
  }

  // ---- Ana çeviri metodu ---- //

  Future<ServiceResult<TranslationResult>> translate({
    required String text,
    required AppLanguage source,
    required AppLanguage target,
  }) async {
    if (_model == null) {
      return const ServiceFailure('Gemini servisi başlatılmamış.');
    }
    if (text.trim().isEmpty) {
      return const ServiceFailure('Çevrilecek metin boş.');
    }
    if (source == target) {
      return ServiceSuccess(
        TranslationResult(
          originalText: text,
          translatedText: text,
          sourceLanguage: source,
          targetLanguage: target,
        ),
      );
    }

    try {
      AppLogger.d(_tag, 'Çeviri: ${source.label} → ${target.label}');

      final prompt = _buildPrompt(text, source, target);
      final response = await _model!.generateContent([Content.text(prompt)]);

      final translated = response.text?.trim();
      if (translated == null || translated.isEmpty) {
        return const ServiceFailure('Gemini boş yanıt döndürdü.');
      }

      AppLogger.i(_tag, 'Çeviri başarılı: "$translated"');

      return ServiceSuccess(
        TranslationResult(
          originalText: text,
          translatedText: translated,
          sourceLanguage: source,
          targetLanguage: target,
        ),
      );
    } on GenerativeAIException catch (e) {
      AppLogger.e(_tag, 'Gemini API hatası', e);
      return ServiceFailure('AI hatası: ${e.message}', error: e);
    } catch (e) {
      AppLogger.e(_tag, 'Beklenmeyen hata', e);
      return ServiceFailure('Çeviri başarısız: $e', error: e);
    }
  }

  // ---- Metin çevirisi (ses olmadan) ---- //

  Future<ServiceResult<TranslationResult>> translateText({
    required String text,
    required AppLanguage source,
    required AppLanguage target,
  }) => translate(text: text, source: source, target: target);

  // ---- Prompt oluşturma ---- //

  String _buildPrompt(String text, AppLanguage source, AppLanguage target) {
    return '''You are a professional translator specializing in tourism contexts.

Translate the following text from ${source.label} to ${target.label}.

Rules:
- Provide ONLY the translated text, nothing else.
- No explanations, no notes, no alternatives.
- Preserve the original tone and formality.
- For numbers and proper nouns, keep them as-is unless there is a standard translation.
- If the text is already in the target language, return it unchanged.

Text to translate:
"$text"

Translation:''';
  }
}