// ============================================================
// lib/services/offline_service.dart
//
// Offline phrase bank — works with zero internet connection.
// Loads JSON files bundled inside the app (assets/phrases/).
// ============================================================

import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

class PhraseCategory {
  final String id;
  final String icon;
  final String color;
  final Map<String, String> label; // language code → label text
  final List<Phrase> phrases;

  const PhraseCategory({
    required this.id,
    required this.icon,
    required this.color,
    required this.label,
    required this.phrases,
  });
}

class Phrase {
  final String id;
  final Map<String, String> translations; // language code → text

  const Phrase({required this.id, required this.translations});

  /// Get translation for a specific language, fallback to English.
  String getText(String languageCode) =>
      translations[languageCode] ?? translations['en'] ?? '';
}

// ------------------------------------------------------------------ //

class OfflineService {
  OfflineService._internal();
  static final OfflineService instance = OfflineService._internal();

  static const _tag = 'OfflineService';
  static const _basePath = 'assets/phrases';

  // Cache loaded categories — load once, use many times.
  final Map<String, PhraseCategory> _cache = {};
  bool _indexLoaded = false;
  List<Map<String, dynamic>> _categoryMeta = [];

  // ================================================================
  //  loadIndex() — Call once at app start.
  // ================================================================
  Future<void> loadIndex() async {
    if (_indexLoaded) return;
    try {
      final raw = await rootBundle.loadString('$_basePath/index.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _categoryMeta = List<Map<String, dynamic>>.from(data['categories']);
      _indexLoaded = true;
      AppLogger.info(_tag, 'Index loaded: ${_categoryMeta.length} categories');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load phrase index', e);
    }
  }

  // ================================================================
  //  getCategory() — Load a category on demand (lazy loading).
  // ================================================================
  Future<PhraseCategory?> getCategory(String categoryId) async {
    if (_cache.containsKey(categoryId)) return _cache[categoryId];

    final meta = _categoryMeta.firstWhere(
      (m) => m['id'] == categoryId,
      orElse: () => {},
    );
    if (meta.isEmpty) return null;

    try {
      final raw = await rootBundle.loadString('$_basePath/${meta['file']}');
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final phrases = (data['phrases'] as List).map((p) {
        final map = Map<String, dynamic>.from(p);
        final id = map.remove('id') as String;
        return Phrase(
          id: id,
          translations: map.map((k, v) => MapEntry(k, v.toString())),
        );
      }).toList();

      final category = PhraseCategory(
        id: categoryId,
        icon: meta['icon'],
        color: meta['color'],
        label: Map<String, String>.from(meta['label']),
        phrases: phrases,
      );

      _cache[categoryId] = category;
      AppLogger.info(_tag, 'Loaded category: $categoryId (${phrases.length} phrases)');
      return category;

    } catch (e) {
      AppLogger.error(_tag, 'Failed to load category: $categoryId', e);
      return null;
    }
  }

  // ================================================================
  //  getAllCategories() — Returns all categories with metadata.
  //  Used to build the category grid on the HomeScreen.
  // ================================================================
  List<Map<String, dynamic>> get categoryList => _categoryMeta;

  // ================================================================
  //  search() — Search phrases across all categories.
  // ================================================================
  Future<List<Phrase>> search(String query, String languageCode) async {
    final results = <Phrase>[];
    final q = query.toLowerCase();

    for (final meta in _categoryMeta) {
      final category = await getCategory(meta['id']);
      if (category == null) continue;

      for (final phrase in category.phrases) {
        final text = phrase.getText(languageCode).toLowerCase();
        if (text.contains(q)) results.add(phrase);
      }
    }

    AppLogger.debug(_tag, 'Search "$query" → ${results.length} results');
    return results;
  }

  /// Clear cache — useful for testing.
  void clearCache() {
    _cache.clear();
    AppLogger.debug(_tag, 'Cache cleared');
  }
}