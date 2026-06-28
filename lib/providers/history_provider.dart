// ============================================================
// lib/providers/history_provider.dart
// Çeviri geçmişi — SharedPreferences ile kalıcı depolama.
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_model.dart';

class HistoryProvider extends ChangeNotifier {
  static const _storageKey = 'translation_history';
  List<TranslationRecord> _records = [];

  List<TranslationRecord> get records => List.unmodifiable(_records);
  List<TranslationRecord> get favorites =>
      _records.where((r) => r.isFavorite).toList();

  int get count => _records.length;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      final List<dynamic> list = json.decode(jsonStr);
      _records = list
          .map((e) => TranslationRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }
  }

  Future<void> addRecord(TranslationRecord record) async {
    _records.insert(0, record);
    // Max 200 kayıt tut
    if (_records.length > 200) {
      _records = _records.sublist(0, 200);
    }
    await _save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final idx = _records.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _records[idx].isFavorite = !_records[idx].isFavorite;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _records.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }
}
