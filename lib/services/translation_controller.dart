// ============================================================
// lib/services/translation_controller.dart
// UI katmanı için tek giriş noktası — AudioService + GeminiService
// koordinasyonu burada yapılır.
// ============================================================

import 'dart:async';

import '../models/service_result.dart';
import '../utils/app_logger.dart';
import 'audio_service.dart';
import 'gemini_service.dart';

// ---- UI'ın tükettiği state modeli ---- //

enum TranslationPhase {
  idle,        // Bekleme
  listening,   // Mikrofon açık
  processing,  // Ses → Gemini işleniyor
  speaking,    // TTS çalıyor
  success,     // Çeviri hazır
  failure,     // Hata
}

class TranslationState {
  final TranslationPhase phase;
  final String partialText;       // Dinleme anında gösterilen anlık metin
  final String recognizedText;    // Tanınan son metin
  final String translatedText;    // Çevrilmiş metin
  final String? errorMessage;
  final AppLanguage sourceLanguage;
  final AppLanguage targetLanguage;

  const TranslationState({
    this.phase           = TranslationPhase.idle,
    this.partialText     = '',
    this.recognizedText  = '',
    this.translatedText  = '',
    this.errorMessage,
    this.sourceLanguage  = AppLanguage.arabic,
    this.targetLanguage  = AppLanguage.turkish,
  });

  TranslationState copyWith({
    TranslationPhase? phase,
    String? partialText,
    String? recognizedText,
    String? translatedText,
    String? errorMessage,
    AppLanguage? sourceLanguage,
    AppLanguage? targetLanguage,
  }) => TranslationState(
    phase:           phase           ?? this.phase,
    partialText:     partialText     ?? this.partialText,
    recognizedText:  recognizedText  ?? this.recognizedText,
    translatedText:  translatedText  ?? this.translatedText,
    errorMessage:    errorMessage,  // null ile sıfırlanabilir
    sourceLanguage:  sourceLanguage  ?? this.sourceLanguage,
    targetLanguage:  targetLanguage  ?? this.targetLanguage,
  );
}

// ---- Controller ---- //

class TranslationController {
  TranslationController._internal();
  static final TranslationController instance = TranslationController._internal();
  static const _tag = 'TranslationController';

  final _stateController = StreamController<TranslationState>.broadcast();
  Stream<TranslationState> get stateStream => _stateController.stream;

  TranslationState _state = const TranslationState();
  TranslationState get currentState => _state;

  StreamSubscription<String>? _partialSub;

  void _emit(TranslationState state) {
    _state = state;
    _stateController.add(state);
    AppLogger.d(_tag, 'State: ${state.phase}');
  }

  // ---- Dil değiştir ---- //

  void setLanguages({AppLanguage? source, AppLanguage? target}) {
    _emit(_state.copyWith(
      sourceLanguage: source,
      targetLanguage: target,
    ));
  }

  void swapLanguages() {
    _emit(_state.copyWith(
      sourceLanguage: _state.targetLanguage,
      targetLanguage: _state.sourceLanguage,
      recognizedText: _state.translatedText,
      translatedText: _state.recognizedText,
    ));
  }

  // ---- Çeviri başlat (mikrofon) ---- //

  Future<void> startTranslation() async {
    if (_state.phase == TranslationPhase.listening) return;

    _emit(_state.copyWith(
      phase: TranslationPhase.listening,
      partialText: '',
      recognizedText: '',
      translatedText: '',
      errorMessage: null,
    ));

    // Anlık metin akışını dinle
    _partialSub?.cancel();
    _partialSub = AudioService.instance.partialTextStream.listen((text) {
      _emit(_state.copyWith(partialText: text));
    });

    final config = RecognitionConfig(localeId: _state.sourceLanguage.bcp47);
    final result = await AudioService.instance.startListening(config);

    await _partialSub?.cancel();

    result.when(
      success: (recognized) async {
        _emit(_state.copyWith(
          phase: TranslationPhase.processing,
          recognizedText: recognized,
          partialText: '',
        ));
        await _translateAndSpeak(recognized);
      },
      failure: (msg) {
        _emit(_state.copyWith(
          phase: TranslationPhase.failure,
          errorMessage: msg,
        ));
      },
    );
  }

  // ---- Dinlemeyi durdur ---- //

  Future<void> stopListening() async {
    await AudioService.instance.stopListening();
  }

  // ---- Metin ile çeviri ---- //

  Future<void> translateText(String text) async {
    if (text.trim().isEmpty) return;

    _emit(_state.copyWith(
      phase: TranslationPhase.processing,
      recognizedText: text,
    ));
    await _translateAndSpeak(text);
  }

  // ---- Son çeviriyi seslendir ---- //

  Future<void> speakTranslation() async {
    if (_state.translatedText.isEmpty) return;

    _emit(_state.copyWith(phase: TranslationPhase.speaking));

    final config = TtsConfig(languageCode: _state.targetLanguage.bcp47);
    await AudioService.instance.speak(_state.translatedText, config);

    _emit(_state.copyWith(phase: TranslationPhase.success));
  }

  // ---- Orijinal metni seslendir ---- //

  Future<void> speakOriginal() async {
    if (_state.recognizedText.isEmpty) return;

    final config = TtsConfig(languageCode: _state.sourceLanguage.bcp47);
    await AudioService.instance.speak(_state.recognizedText, config);
  }

  // ---- Sıfırla ---- //

  void reset() {
    AudioService.instance.stopSpeaking();
    AudioService.instance.stopListening();
    _emit(TranslationState(
      sourceLanguage: _state.sourceLanguage,
      targetLanguage: _state.targetLanguage,
    ));
  }

  // ---- İç çeviri + TTS akışı ---- //

  Future<void> _translateAndSpeak(String text) async {
    final result = await GeminiService.instance.translate(
      text: text,
      source: _state.sourceLanguage,
      target: _state.targetLanguage,
    );

    result.when(
      success: (translation) async {
        _emit(_state.copyWith(
          phase: TranslationPhase.success,
          translatedText: translation.translatedText,
        ));
        // Otomatik seslendir
        await speakTranslation();
      },
      failure: (msg) {
        _emit(_state.copyWith(
          phase: TranslationPhase.failure,
          errorMessage: msg,
        ));
      },
    );
  }

  Future<void> dispose() async {
    await _partialSub?.cancel();
    await _stateController.close();
  }
}