// ============================================================
// lib/services/translation_controller.dart
//
// WHY THIS EXISTS:
//   Halit's UI should call ONE object, not two.
//   If his button had to know about AudioService AND
//   GeminiService AND error handling AND state management,
//   the UI file would become unmaintainable.
//
//   This controller is the PUBLIC API for the UI layer:
//     1. User taps mic button  → startTranslation()
//     2. User releases button  → stopListening()
//     3. User taps play button → speakTranslation()
//
//   The UI only cares about TranslationState — it subscribes
//   to the stream and reacts to whatever arrives.
//
// HOW TO USE (Halit's side):
//
//   // In initState:
//   TranslationController.instance.stateStream.listen((state) {
//     setState(() => _state = state);
//   });
//
//   // Mic button (GestureDetector onLongPress):
//   await TranslationController.instance.startTranslation(
//     sourceLanguage: AppLanguage.arabic,
//     targetLanguage: AppLanguage.turkish,
//   );
//
//   // Mic button release (onLongPressEnd):
//   await TranslationController.instance.stopListening();
//
//   // Play button:
//   await TranslationController.instance.speakTranslation();
//
//   // In dispose:
//   TranslationController.instance.dispose();
// ============================================================

import 'dart:async';

import '../models/service_result.dart';
import '../utils/app_logger.dart';
import 'audio_service.dart';
import 'gemini_service.dart';

// ---- State model that the UI consumes ---- //

enum TranslationPhase {
  idle,        // Nothing happening.
  listening,   // Mic is open.
  processing,  // Got speech, calling Gemini.
  success,     // Translation ready.
  failure,     // Something went wrong.
}

class TranslationState {
  final TranslationPhase phase;

  /// Live partial speech text — shown while user is still talking.
  final String           partialText;

  /// Final recognized speech.
  final String           recognizedText;

  /// Translated output.
  final String           translatedText;

  /// Human-readable error to display in a SnackBar / Dialog.
  final String?          errorMessage;

  const TranslationState({
    this.phase          = TranslationPhase.idle,
    this.partialText    = '',
    this.recognizedText = '',
    this.translatedText = '',
    this.errorMessage,
  });

  TranslationState copyWith({
    TranslationPhase? phase,
    String?           partialText,
    String?           recognizedText,
    String?           translatedText,
    String?           errorMessage,
  }) =>
      TranslationState(
        phase:          phase          ?? this.phase,
        partialText:    partialText    ?? this.partialText,
        recognizedText: recognizedText ?? this.recognizedText,
        translatedText: translatedText ?? this.translatedText,
        errorMessage:   errorMessage,
      );
}

// ------------------------------------------------------------------ //

class TranslationController {
  TranslationController._internal();

  static final TranslationController instance = TranslationController._internal();

  static const _tag = 'TranslationController';

  final _audio  = AudioService.instance;
  final _gemini = GeminiService.instance;

  // Stream of states — the UI subscribes to this.
  final _stateController = StreamController<TranslationState>.broadcast();
  Stream<TranslationState> get stateStream => _stateController.stream;

  TranslationState _state = const TranslationState();
  TranslationState get currentState => _state;

  // Last successful translation — needed by speakTranslation().
  TranslationResult? _lastTranslation;

  // ================================================================
  //  initialize()
  //  Call once — await TranslationController.instance.initialize()
  //  in your app's startup code (e.g. SplashScreen or main()).
  // ================================================================
  Future<ServiceResult<void>> initialize() async {
    AppLogger.info(_tag, 'Initializing...');
    return _audio.initialize();
  }

  // ================================================================
  //  startTranslation()
  //  Opens the mic and kicks off the full pipeline:
  //    mic → STT → Gemini → result in stateStream
  // ================================================================
  Future<void> startTranslation({
    required AppLanguage sourceLanguage,
    required AppLanguage targetLanguage,
  }) async {
    _emit(_state.copyWith(
      phase:       TranslationPhase.listening,
      partialText: '',
      errorMessage: null,
    ));

    final result = await _audio.startListening(
      config: RecognitionConfig(localeId: sourceLanguage.bcp47),

      onPartialResult: (partial) {
        _emit(_state.copyWith(partialText: partial));
      },

      onFinalResult: (text) async {
        _emit(_state.copyWith(
          phase:          TranslationPhase.processing,
          recognizedText: text,
          partialText:    '',
        ));

        await _runTranslation(
          text:   text,
          source: sourceLanguage,
          target: targetLanguage,
        );
      },
    );

    if (result.isFailure) {
      _emitError(result.failure!.userMessage);
    }
  }

  // ================================================================
  //  stopListening()
  //  Call when user releases the mic button.
  // ================================================================
  Future<void> stopListening() async {
    await _audio.stopListening();
    // If we're still in listening phase (user released quickly without speech):
    if (_state.phase == TranslationPhase.listening) {
      _emit(_state.copyWith(phase: TranslationPhase.idle));
    }
  }

  // ================================================================
  //  speakTranslation()
  //  Plays the last translated text aloud.
  //  Halit can wire this to the play/speaker button.
  // ================================================================
  Future<void> speakTranslation() async {
    final translation = _lastTranslation;

    if (translation == null) {
      AppLogger.warning(_tag, 'speakTranslation() called with no translation available.');
      return;
    }

    await _audio.speak(
      translation.translatedText,
      config: TtsConfig(languageCode: translation.targetLanguage.bcp47),
    );
  }

  // ================================================================
  //  stopSpeaking()
  // ================================================================
  Future<void> stopSpeaking() => _audio.stopSpeaking();

  // ================================================================
  //  _runTranslation()  — private pipeline step
  // ================================================================
  Future<void> _runTranslation({
    required String      text,
    required AppLanguage source,
    required AppLanguage target,
  }) async {
    final result = await _gemini.translate(
      text:   text,
      source: source,
      target: target,
    );

    if (result.isSuccess) {
      _lastTranslation = result.value;
      _emit(_state.copyWith(
        phase:          TranslationPhase.success,
        translatedText: result.value.translatedText,
      ));

      // Auto-speak the translation after it arrives.
      await speakTranslation();

    } else {
      _emitError(result.failure!.userMessage);
    }
  }

  // ---- Private helpers ---- //

  void _emit(TranslationState newState) {
    _state = newState;
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  void _emitError(String message) {
    AppLogger.error(_tag, 'Error state: $message');
    _emit(_state.copyWith(
      phase:        TranslationPhase.failure,
      errorMessage: message,
    ));
  }

  // ===================نس=============================================
  //  dispose()
  //  Call in the root widget's dispose().
  // ================================================================
  Future<void> dispose() async {
    await _audio.dispose();
    await _stateController.close();
    AppLogger.info(_tag, 'Disposed.');
  }
}