import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/env.dart';
import '../models/service_result.dart';
import '../utils/app_logger.dart';

enum AppLanguage {
  arabic(code: 'ar', label: 'العربية', bcp47: 'ar-SA'),
  english(code: 'en', label: 'English', bcp47: 'en-US'),
  turkish(code: 'tr', label: 'Türkçe', bcp47: 'tr-TR'),
  german(code: 'de', label: 'Deutsch', bcp47: 'de-DE'),
  french(code: 'fr', label: 'Français', bcp47: 'fr-FR'),
  spanish(code: 'es', label: 'Español', bcp47: 'es-ES'),
  russian(code: 'ru', label: 'Русский', bcp47: 'ru-RU'),
  chinese(code: 'zh', label: '中文', bcp47: 'zh-CN'),
  japanese(code: 'ja', label: '日本語', bcp47: 'ja-JP');

  const AppLanguage({
    required this.code,
    required this.label,
    required this.bcp47,
  });

  final String code;
  final String label;
  final String bcp47;
}

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

class GeminiService {
  GeminiService._internal();
  static final GeminiService instance = GeminiService._internal();
  static const _tag = 'GeminiService';

  GenerativeModel? _model;

  void _initModel() {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: Env.geminiApiKey,
      systemInstruction: Content.system(
        'You are a precise translation engine for a tourist assistance app. '
        'Rules: '
        '1. Return ONLY the translated text — no explanations, no quotes, no labels. '
        '2. Preserve the original meaning, tone, and urgency. '
        '3. Keep it natural and conversational. '
        '4. If the input is already in the target language, return it unchanged. '
        '5. Never add disclaimers or commentary.',
      ),
    );
  }

  Future<ServiceResult<TranslationResult>> translate({
    required String text,
    required AppLanguage source,
    required AppLanguage target,
  }) async {
    if (text.trim().isEmpty) {
      return ServiceResult.fail(ServiceFailure.apiError('Empty text'));
    }

    _initModel();

    int attempt = 0;
    while (attempt <= Env.geminiMaxRetries) {
      try {
        final response = await _model!.generateContent([
          Content.text(
            'Translate the following ${source.label} text to ${target.label}:\n${text.trim()}',
          ),
        ]).timeout(Env.geminiTimeout);

        final translated = response.text?.trim();
        if (translated == null || translated.isEmpty) {
          throw Exception('Empty response from Gemini');
        }

        AppLogger.info(_tag, 'Translation success: "$translated"');
        return ServiceResult.success(TranslationResult(
          originalText: text.trim(),
          translatedText: translated,
          sourceLanguage: source,
          targetLanguage: target,
        ));

      } catch (e, stack) {
        AppLogger.error(_tag, 'Attempt $attempt failed.', e, stack);
        if (attempt >= Env.geminiMaxRetries) {
          return ServiceResult.fail(ServiceFailure.unknown(e));
        }
      }
      attempt++;
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }
    return ServiceResult.fail(ServiceFailure.unknown('Retry loop exited'));
  }
}