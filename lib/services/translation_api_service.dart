// ============================================================
// lib/services/translation_api_service.dart
// Ücretsiz çeviri servisi — API anahtarı GEREKMEZ.
// MyMemory API + İngilizce köprü çevirisi (boş sonuç yedek).
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

    AppLogger.i(_tag, 'Çeviri: ${source.code} → ${target.code}: "$text"');

    // 1. Doğrudan çeviri dene
    String? result = await _callGoogleTranslate(text, source.code, target.code);

    // 2. Boş dönerse → İngilizce üzerinden köprü çevirisi
    if (result == null && source.code != 'en' && target.code != 'en') {
      AppLogger.i(_tag, 'Köprü çevirisi: ${source.code} → en → ${target.code}');
      
      final toEnglish = await _callGoogleTranslate(text, source.code, 'en');
      if (toEnglish != null) {
        result = await _callGoogleTranslate(toEnglish, 'en', target.code);
      }
    }

    // 3. Hala boşsa → MyMemory yedek servisi dene
    if (result == null) {
      AppLogger.i(_tag, 'Yedek çeviri servisi deneniyor (MyMemory)...');
      result = await _callMyMemory(text, source.code, target.code);
    }

    if (result != null) {
      AppLogger.i(_tag, '✅ Çeviri başarılı: "$result"');
      return ServiceSuccess(
        TranslationResult(
          originalText: text,
          translatedText: result,
          sourceLanguage: source,
          targetLanguage: target,
        ),
      );
    }

    return const ServiceFailure(
      'Çeviri yapılamadı. Lütfen tekrar deneyin.',
    );
  }

  // ---- MyMemory Free API ---- //

  Future<String?> _callMyMemory(String text, String fromCode, String toCode) async {
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$fromCode|$toCode',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final match = json['responseData']?['translatedText']?.toString().trim();
        if (match != null && match.isNotEmpty && !match.contains('MYMEMORY WARNING')) {
          AppLogger.d(_tag, 'MyMemory OK ($fromCode→$toCode): "$match"');
          return match;
        }
      }
    } catch (e) {
      AppLogger.w(_tag, 'MyMemory hata: $e');
    }
    return null;
  }

  // ---- Google Translate Free API (gtx) ---- //

  Future<String?> _callGoogleTranslate(String text, String fromCode, String toCode) async {
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$fromCode&tl=$toCode&dt=t&q=${Uri.encodeComponent(text)}'
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List && json.isNotEmpty && json[0] is List && json[0].isNotEmpty) {
          // json[0] contains the translated segments
          final segments = json[0] as List;
          StringBuffer translated = StringBuffer();
          for (var segment in segments) {
            if (segment is List && segment.isNotEmpty) {
              translated.write(segment[0]);
            }
          }
          final result = translated.toString().trim();
          if (result.isNotEmpty) {
            AppLogger.d(_tag, 'Google OK ($fromCode→$toCode): "$result"');
            return result;
          }
        }
      }
    } catch (e) {
      AppLogger.w(_tag, 'Google hata ($fromCode→$toCode): $e');
    }

    return null;
  }
}
