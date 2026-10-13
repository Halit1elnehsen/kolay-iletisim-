// File: lib/services/marker_storage_service.dart
// Description: Local storage for custom markers and search history using SharedPreferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_marker.dart';
import '../utils/app_logger.dart';

class MarkerStorageService {
  MarkerStorageService._internal();
  static final MarkerStorageService instance = MarkerStorageService._internal();

  static const String _tag = 'MarkerStorageService';
  static const String _markersKey = 'custom_markers';
  static const String _searchHistoryKey = 'search_history';

  Future<List<CustomMarker>> loadMarkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersJsonList = prefs.getStringList(_markersKey) ?? [];
      
      final markers = <CustomMarker>[];
      for (final jsonStr in markersJsonList) {
        try {
          final marker = CustomMarker.tryFromJson(json.decode(jsonStr));
          if (marker != null) markers.add(marker);
        } catch (_) {
          // Bozuk kayıt atlanıyor
        }
      }
      return markers;
    } catch (e) {
      AppLogger.e(_tag, 'İşaretçiler yüklenirken hata oluştu', e);
      return [];
    }
  }

  Future<void> saveMarkers(List<CustomMarker> markers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersJsonList = markers.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_markersKey, markersJsonList);
      AppLogger.d(_tag, '${markers.length} işaretçi kaydedildi');
    } catch (e) {
      AppLogger.e(_tag, 'İşaretçiler kaydedilirken hata oluştu', e);
    }
  }

  Future<void> addMarker(CustomMarker marker) async {
    final markers = await loadMarkers();
    markers.add(marker);
    await saveMarkers(markers);
  }

  Future<void> removeMarker(String id) async {
    final markers = await loadMarkers();
    markers.removeWhere((m) => m.id == id);
    await saveMarkers(markers);
  }

  Future<void> updateMarker(CustomMarker marker) async {
    final markers = await loadMarkers();
    final index = markers.indexWhere((m) => m.id == marker.id);
    if (index != -1) {
      markers[index] = marker;
      await saveMarkers(markers);
    }
  }

  Future<List<String>> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      AppLogger.e(_tag, 'Arama geçmişi yüklenirken hata oluştu', e);
      return [];
    }
  }

  Future<void> addSearchHistory(String query) async {
    try {
      final history = await loadSearchHistory();
      history.remove(query);
      history.insert(0, query);
      
      if (history.length > 5) {
        history.removeRange(5, history.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, history);
      AppLogger.d(_tag, '"$query" arama geçmişine eklendi');
    } catch (e) {
      AppLogger.e(_tag, 'Arama geçmişi eklenirken hata oluştu', e);
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      AppLogger.d(_tag, 'Arama geçmişi temizlendi');
    } catch (e) {
      AppLogger.e(_tag, 'Arama geçmişi temizlenirken hata oluştu', e);
    }
  }
}
