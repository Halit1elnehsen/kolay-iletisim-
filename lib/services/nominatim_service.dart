// ============================================================
// lib/services/nominatim_service.dart
// Nominatim (OpenStreetMap) yer arama servisi.
// Rate limit, önbellek ve hata yönetimi dahil.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_result.dart';
import '../models/search_result.dart';
import '../utils/app_logger.dart';

class NominatimService {
  NominatimService._internal();
  static final NominatimService instance = NominatimService._internal();

  static const String _tag = 'NominatimService';
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const int _rateLimitMs = 1100;
  static const int _timeoutSeconds = 10;
  static const int _maxCacheSize = 20;
  static const int _minQueryLength = 2;

  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, List<SearchResult>> _cache = {};
  int _currentRequestId = 0;

  Future<ServiceResult<List<SearchResult>>> search(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < _minQueryLength) {
      return const ServiceSuccess([]);
    }

    // Önbellekten döndür
    if (_cache.containsKey(trimmedQuery)) {
      AppLogger.d(_tag, 'Önbellekten: "$trimmedQuery"');
      return ServiceSuccess(_cache[trimmedQuery]!);
    }

    // Rate limiting
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime).inMilliseconds;
    if (elapsed < _rateLimitMs) {
      await Future.delayed(Duration(milliseconds: _rateLimitMs - elapsed));
    }
    _lastRequestTime = DateTime.now();

    // Eski isteklerin sonuçlarının üzerine yazmasını engelle
    final requestId = ++_currentRequestId;

    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(trimmedQuery)}&format=json&limit=8&addressdetails=1',
      );

      AppLogger.i(_tag, 'Aranıyor: "$trimmedQuery"');

      final response = await http.get(uri, headers: {
        'User-Agent': 'SpeakBridge/1.0 (kolay-iletisim-app)',
        'Accept-Language': 'tr,en',
        'Referer': 'https://speakbridge.app',
      }).timeout(const Duration(seconds: _timeoutSeconds));

      // Bu istek artık geçerli değilse sonucu görmezden gel
      if (requestId != _currentRequestId) {
        return const ServiceSuccess([]);
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final results = jsonList
            .map((j) => SearchResult.fromNominatimJson(j as Map<String, dynamic>))
            .toList();

        // LRU cache
        if (_cache.length >= _maxCacheSize) {
          _cache.remove(_cache.keys.first);
        }
        _cache[trimmedQuery] = results;

        AppLogger.i(_tag, '${results.length} sonuç bulundu');
        return ServiceSuccess(results);
      } else if (response.statusCode == 429) {
        AppLogger.w(_tag, 'Rate limit aşıldı');
        return const ServiceFailure('Çok fazla arama yapıldı. Lütfen biraz bekleyin.');
      } else {
        AppLogger.e(_tag, 'HTTP hatası: ${response.statusCode}');
        return ServiceFailure('Arama sunucusu yanıt vermedi (Hata: ${response.statusCode}).');
      }
    } catch (e) {
      if (requestId != _currentRequestId) {
        return const ServiceSuccess([]);
      }
      AppLogger.e(_tag, 'Arama hatası', e);
      return const ServiceFailure('Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
