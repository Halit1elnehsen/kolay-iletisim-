// ============================================================
// lib/services/translation_api_service.dart
// Ücretsiz çeviri servisi — API anahtarı GEREKMEZ.
// Birincil: MyMemory API (profesyonel kalite)
// Yedek:   Lingva Translate (Google Translate proxy)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';
import '../models/service_result.dart';
import 'gemini_service.dart'; // AppLanguage ve TranslationResult için

class TranslationApiService {
  TranslationApiService._internal();
  static final TranslationApiService instance = TranslationApiService._internal();
  static const _tag = 'TranslationApiService';

  // ---- Ana çeviri metodu ---- //

  Future<ServiceResult<TranslationResult>> translate({
    required String text,
    required AppLanguage source,
    required AppLanguage target,
  }) async {
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

    // 1. Önce MyMemory API'yi dene (en iyi ücretsiz servis)
    try {
      final result = await _translateWithMyMemory(text, source, target);
      if (result != null) {
        AppLogger.i(_tag, 'MyMemory çeviri başarılı');
        return ServiceSuccess(
          TranslationResult(
            originalText: text,
            translatedText: result,
            sourceLanguage: source,
            targetLanguage: target,
          ),
        );
      }
    } catch (e) {
      AppLogger.w(_tag, 'MyMemory başarısız, Lingva deneniyor: $e');
    }

    // 2. Yedek: Lingva Translate (Google Translate proxy)
    try {
      final result = await _translateWithLingva(text, source, target);
      if (result != null) {
        AppLogger.i(_tag, 'Lingva çeviri başarılı');
        return ServiceSuccess(
          TranslationResult(
            originalText: text,
            translatedText: result,
            sourceLanguage: source,
            targetLanguage: target,
          ),
        );
      }
    } catch (e) {
      AppLogger.e(_tag, 'Lingva da başarısız: $e');
    }

    return const ServiceFailure(
      'Çeviri şu anda yapılamadı. İnternet bağlantınızı kontrol edin.',
    );
  }

  // ---- MyMemory API ---- //
  // Ücretsiz, günde 5000 kelime, profesyonel kalite.
  // https://mymemory.translated.net/doc/spec.php

  Future<String?> _translateWithMyMemory(
    String text,
    AppLanguage source,
    AppLanguage target,
  ) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': '${source.code}|${target.code}',
      'de': 'speakbridge@app.com', // Ücretsiz limit artışı için e-posta
    });

    AppLogger.d(_tag, 'MyMemory isteği: ${source.code} → ${target.code}');

    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['responseData'];

      if (data != null && data['translatedText'] != null) {
        final translated = data['translatedText'] as String;

        // MyMemory bazen hata mesajı döndürür, kontrol et
        if (translated.isNotEmpty &&
            !translated.toUpperCase().contains('MYMEMORY WARNING') &&
            !translated.toUpperCase().contains('LIMIT')) {
          return translated;
        }
      }
    }

    return null;
  }

  // ---- Lingva Translate API ---- //
  // Google Translate'in ücretsiz proxy'si. API anahtarı gerektirmez.
  // https://github.com/thedaviddelta/lingva-translate

  static const _lingvaInstances = [
    'lingva.ml',
    'lingva.lunar.icu',
    'translate.plausibility.cloud',
  ];

  Future<String?> _translateWithLingva(
    String text,
    AppLanguage source,
    AppLanguage target,
  ) async {
    for (final host in _lingvaInstances) {
      try {
        final uri = Uri.https(
          host,
          '/api/v1/${source.code}/${target.code}/${Uri.encodeComponent(text)}',
        );

        AppLogger.d(_tag, 'Lingva isteği: $host');

        final response = await http.get(uri).timeout(
          const Duration(seconds: 8),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final translation = json['translation'] as String?;
          if (translation != null && translation.isNotEmpty) {
            return translation;
          }
        }
      } catch (e) {
        AppLogger.w(_tag, 'Lingva instance $host başarısız: $e');
        continue; // Sonraki instance'ı dene
      }
    }

    return null;
  }
}
