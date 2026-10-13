// ============================================================
// lib/services/map_preferences_service.dart
// Harita tercihlerini yerel depolamada saklama servisi.
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../config/map_tile_config.dart';
import '../utils/app_logger.dart';

class MapPreferencesService {
  MapPreferencesService._internal();
  static final MapPreferencesService instance = MapPreferencesService._internal();

  static const String _tag = 'MapPreferencesService';
  static const String _mapTypeKey = 'map_tile_type';
  static const String _cyclingLayerKey = 'cycling_layer_active';

  Future<MapTileType> loadMapType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_mapTypeKey);
      if (index != null && index >= 0 && index < MapTileType.values.length) {
        return MapTileType.values[index];
      }
    } catch (e) {
      AppLogger.e(_tag, 'Harita türü yüklenirken hata', e);
    }
    return MapTileType.normal; // Varsayılan
  }

  Future<void> saveMapType(MapTileType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_mapTypeKey, type.index);
    } catch (e) {
      AppLogger.e(_tag, 'Harita türü kaydedilirken hata', e);
    }
  }

  Future<bool> loadCyclingLayer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cyclingLayerKey) ?? false;
    } catch (e) {
      AppLogger.e(_tag, 'Bisiklet katmanı yüklenirken hata', e);
    }
    return false;
  }

  Future<void> saveCyclingLayer(bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cyclingLayerKey, active);
    } catch (e) {
      AppLogger.e(_tag, 'Bisiklet katmanı kaydedilirken hata', e);
    }
  }
}
