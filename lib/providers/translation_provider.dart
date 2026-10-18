// ============================================================
// lib/providers/translation_provider.dart
// UI ↔ TranslationController köprüsü — ChangeNotifier pattern.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/translation_controller.dart';
import '../services/gemini_service.dart';
import '../models/translation_model.dart';
import 'history_provider.dart';
import 'settings_provider.dart';

class TranslationProvider extends ChangeNotifier {
  TranslationState _state = const TranslationState();
  TranslationState get state => _state;

  StreamSubscription<TranslationState>? _sub;
  final TextEditingController textController = TextEditingController();

  HistoryProvider? _historyProvider;
  SettingsProvider? _settingsProvider;
  String _lastSavedTranslation = '';

  TranslationProvider() {
    _sub = TranslationController.instance.stateStream.listen((s) {
      _state = s;
      final live = s.partialText.isNotEmpty ? s.partialText : s.recognizedText;
      if (live.isNotEmpty && textController.text != live) {
        textController.text = live;
        textController.selection = TextSelection.collapsed(offset: live.length);
      }

      // Save to history on success
      if (s.phase == TranslationPhase.success &&
          s.translatedText.isNotEmpty &&
          s.translatedText != _lastSavedTranslation) {
        _lastSavedTranslation = s.translatedText;
        _historyProvider?.addRecord(
          TranslationRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            originalText: s.recognizedText,
            translatedText: s.translatedText,
            sourceLanguageCode: s.sourceLanguage.code,
            targetLanguageCode: s.targetLanguage.code,
            sourceLanguageLabel: s.sourceLanguage.label,
            targetLanguageLabel: s.targetLanguage.label,
            createdAt: DateTime.now(),
          ),
        );
      }

      notifyListeners();
    });
  }

  void bind(HistoryProvider history, SettingsProvider settings) {
    _historyProvider = history;
    _settingsProvider = settings;

    // Apply default source/target if first run
    if (_state.phase == TranslationPhase.idle &&
        _state.translatedText.isEmpty &&
        textController.text.isEmpty &&
        _state.sourceLanguage == AppLanguage.arabic &&
        _state.targetLanguage == AppLanguage.turkish) {
      if (settings.defaultSource != _state.sourceLanguage ||
          settings.defaultTarget != _state.targetLanguage) {
        setSource(settings.defaultSource);
        setTarget(settings.defaultTarget);
      }
    }
  }

  // Kısayollar
  TranslationPhase get phase => _state.phase;
  bool get isListening => _state.phase == TranslationPhase.listening;
  bool get isProcessing => _state.phase == TranslationPhase.processing;
  bool get isSpeaking => _state.phase == TranslationPhase.speaking;
  bool get hasTranslation => _state.translatedText.isNotEmpty;
  bool get hasError => _state.phase == TranslationPhase.failure;
  String get error => _state.errorMessage ?? '';
  AppLanguage get source => _state.sourceLanguage;
  AppLanguage get target => _state.targetLanguage;

  // Dil değiştir
  void setSource(AppLanguage lang) {
    TranslationController.instance.setLanguages(source: lang);
  }

  void setTarget(AppLanguage lang) {
    TranslationController.instance.setLanguages(target: lang);
  }

  void swapLanguages() {
    TranslationController.instance.swapLanguages();
    if (_state.recognizedText.isNotEmpty) {
      textController.text = _state.recognizedText;
      textController.selection =
          TextSelection.collapsed(offset: textController.text.length);
    }
    notifyListeners();
  }

  // Ses çevirisi
  Future<void> startListening() async {
    final autoSpeak = _settingsProvider?.autoSpeak ?? true;
    final speechRate = _settingsProvider?.speechRate ?? 0.45;
    await TranslationController.instance.startTranslation(
      autoSpeak: autoSpeak,
      speechRate: speechRate,
    );
  }

  Future<void> stopListening() async {
    await TranslationController.instance.stopListening();
  }

  // Metin çevirisi
  Future<void> translateText() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    final autoSpeak = _settingsProvider?.autoSpeak ?? true;
    final speechRate = _settingsProvider?.speechRate ?? 0.45;
    await TranslationController.instance.translateText(
      text,
      autoSpeak: autoSpeak,
      speechRate: speechRate,
    );
  }

  // TTS
  Future<void> speakTranslation() async {
    final speechRate = _settingsProvider?.speechRate ?? 0.45;
    await TranslationController.instance.speakTranslation(speechRate: speechRate);
  }

  Future<void> speakOriginal() async {
    final speechRate = _settingsProvider?.speechRate ?? 0.45;
    await TranslationController.instance.speakOriginal(speechRate: speechRate);
  }

  // Sıfırla
  void reset() {
    textController.clear();
    _lastSavedTranslation = '';
    TranslationController.instance.reset();
  }

  @override
  void dispose() {
    _sub?.cancel();
    textController.dispose();
    super.dispose();
  }
}
