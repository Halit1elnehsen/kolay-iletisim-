// ============================================================
// lib/providers/translation_provider.dart
// UI ↔ TranslationController köprüsü — ChangeNotifier pattern.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/translation_controller.dart';
import '../services/gemini_service.dart';

class TranslationProvider extends ChangeNotifier {
  TranslationState _state = const TranslationState();
  TranslationState get state => _state;

  StreamSubscription<TranslationState>? _sub;
  final TextEditingController textController = TextEditingController();

  TranslationProvider() {
    _sub = TranslationController.instance.stateStream.listen((s) {
      _state = s;
      notifyListeners();
    });
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
  }

  // Ses çevirisi
  Future<void> startListening() async {
    await TranslationController.instance.startTranslation();
  }

  Future<void> stopListening() async {
    await TranslationController.instance.stopListening();
  }

  // Metin çevirisi
  Future<void> translateText() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    await TranslationController.instance.translateText(text);
  }

  // TTS
  Future<void> speakTranslation() async {
    await TranslationController.instance.speakTranslation();
  }

  Future<void> speakOriginal() async {
    await TranslationController.instance.speakOriginal();
  }

  // Sıfırla
  void reset() {
    textController.clear();
    TranslationController.instance.reset();
  }

  @override
  void dispose() {
    _sub?.cancel();
    textController.dispose();
    super.dispose();
  }
}
