// ============================================================
// lib/config/map_tile_config.dart
// Centralized map tile configuration
// ============================================================

import 'package:flutter/material.dart';

enum MapTileType {
  normal,
  satellite,
  terrain,
  dark,
}

class MapTileConfig {
  static const String userAgentPackageName = 'com.speakbridge.app';
  
  static const String cyclOsmUrl = 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png';
  static const List<String> cyclOsmSubdomains = ['a', 'b', 'c'];

  static String urlTemplate(MapTileType type) {
    switch (type) {
      case MapTileType.normal:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTileType.satellite:
        return 'https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTileType.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapTileType.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
    }
  }

  static List<String> subdomains(MapTileType type) {
    if (type == MapTileType.dark) {
      return ['a', 'b', 'c', 'd'];
    }
    return const [];
  }

  static String attribution(MapTileType type) {
    switch (type) {
      case MapTileType.normal:
        return '© OpenStreetMap contributors';
      case MapTileType.satellite:
        return 'Sources: Esri, Maxar, Earthstar Geographics';
      case MapTileType.terrain:
        return '© OpenStreetMap contributors, SRTM | Map: © OpenTopoMap (CC-BY-SA)';
      case MapTileType.dark:
        return '© CARTO, © OpenStreetMap contributors';
    }
  }

  static String label(MapTileType type) {
    switch (type) {
      case MapTileType.normal:
        return 'Normal';
      case MapTileType.satellite:
        return 'Uydu';
      case MapTileType.terrain:
        return 'Arazi';
      case MapTileType.dark:
        return 'Karanlık';
    }
  }

  static IconData icon(MapTileType type) {
    switch (type) {
      case MapTileType.normal:
        return Icons.map;
      case MapTileType.satellite:
        return Icons.satellite;
      case MapTileType.terrain:
        return Icons.terrain;
      case MapTileType.dark:
        return Icons.dark_mode;
    }
  }
}
