// ============================================================
// lib/services/audio_service.dart
//
// Responsibilities:
//   • Speech-to-Text  — microphone → text  (on-device, offline-capable)
//   • Text-to-Speech  — text → spoken audio (on-device, offline-capable)
//
// Architecture decisions & why:
//   ┌──────────────────────────────────────────────────────────┐
//   │ SINGLETON                                                │
//   │ AudioService.instance is the only instance that ever    │
//   │ exists. Creating multiple instances causes mic resource  │
//   │ conflicts on Android and audio session fights on iOS.   │
//   │                                                          │
//   │ INITIALIZATION GUARD                                     │
//   │ Every public method checks _isReady. If initialize()    │
//   │ hasn't been called (or failed), callers get a typed     │
//   │ ServiceFailure instead of a NullPointerException.       │
//   │                                                          │
//   │ ServiceResult<T> return types                           │
//   │ No exceptions cross service boundaries. The UI layer    │
//   │ pattern-matches on isSuccess/isFailure and shows the    │
//   │ right message without knowing internals.                │
//   │                                                          │
//   │ STREAMS                                                  │
//   │ listeningStateStream lets the UI reactively update its  │
//   │ mic-button animation without polling.                   │
//   └──────────────────────────────────────────────────────────┘
// ============================================================

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../models/service_result.dart';
import '../utils/app_logger.dart';

// ---- Public data types exposed to callers ---- //

enum ListeningState { idle, listening, processing }

class RecognitionConfig {
  /// BCP-47 locale tag, e.g. 'ar-SA', 'en-US', 'tr-TR'.
  final String localeId;

  /// Maximum time to keep the mic open while the user is silent.
  final Duration listenFor;

  /// Stop listening after this much silence.
  final Duration pauseFor;

  const RecognitionConfig({
    this.localeId = 'ar-SA',
    this.listenFor = const Duration(seconds: 30),
    this.pauseFor  = const Duration(seconds: 3),
  });
}

class TtsConfig {
  /// BCP-47 locale for the spoken output, e.g. 'tr-TR'.
  final String languageCode;
  final double speechRate; // 0.0 – 1.0
  final double volume;     // 0.0 – 1.0
  final double pitch;      // 0.5 – 2.0

  const TtsConfig({
    this.languageCode = 'tr-TR',
    this.speechRate   = 0.45,
    this.volume       = 1.0,
    this.pitch        = 1.0,
  });
}

// ------------------------------------------------------------------ //

class AudioService {
  AudioService._internal();

  /// The one and only instance — use everywhere.
  static final AudioService instance = AudioService._internal();

  static const _tag = 'AudioService';

  // ---- Internal state ---- //
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts        _tts = FlutterTts();

  bool _isReady        = false;
  bool _isTtsReady     = false;
  bool _isDisposed     = false;

  // Stream that the UI can listen to for live mic state changes.
  final _listeningStateController =
      StreamController<ListeningState>.broadcast();

  Stream<ListeningState> get listeningStateStream =>
      _listeningStateController.stream;

  ListeningState _currentState = ListeningState.idle;

  // ================================================================
  //  initialize()
  //  Call once — typically in main() or an app-level provider.
  //  Safe to call multiple times (idempotent).
  // ================================================================
  Future<ServiceResult<void>> initialize() async {
    if (_isReady) return ServiceResult.ok();
    if (_isDisposed) {
      return ServiceResult.fail(ServiceFailure.unknown('AudioService was disposed. Create a new instance.'));
    }

    try {
      // --- Speech-to-Text --- //
      final sttAvailable = await _stt.initialize(
        onError:  _onSttError,
        onStatus: _onSttStatus,
        // debugLogging only in dev builds — AppLogger handles this.
        debugLogging: false,
      );

      if (!sttAvailable) {
        AppLogger.warning(_tag, 'STT not available on this device.');
        // Not a hard failure — the app can still run in TTS-only or offline mode.
      }

      // --- Text-to-Speech --- //
      await _initTts();

      _isReady = true;
      AppLogger.info(_tag, 'Initialized. STT=$sttAvailable  TTS=$_isTtsReady');
      return ServiceResult.ok();

    } catch (e, stack) {
      AppLogger.error(_tag, 'Initialization failed.', e, stack);
      return ServiceResult.fail(ServiceFailure.unknown(e));
    }
  }

  Future<void> _initTts() async {
    try {
      // Check available languages — TTS silently fails on some Android ROMs
      // if the requested language pack isn't installed.
      final languages = await _tts.getLanguages as List<dynamic>;
      AppLogger.debug(_tag, 'TTS languages available: ${languages.length}');

      // Wire up lifecycle callbacks so we can react to speech events.
      _tts.setStartHandler(()    => AppLogger.debug(_tag, 'TTS: started speaking'));
      _tts.setCompletionHandler(()=> AppLogger.debug(_tag, 'TTS: finished speaking'));
      _tts.setErrorHandler((msg) => AppLogger.error(_tag, 'TTS error: $msg'));

      // Apply defaults — callers can override per speak() call.
      await _applyTtsConfig(const TtsConfig());

      _isTtsReady = true;
    } catch (e) {
      AppLogger.warning(_tag, 'TTS init partially failed: $e');
      // Not re-thrown — STT might still work fine.
    }
  }

  Future<void> _applyTtsConfig(TtsConfig config) async {
    await _tts.setLanguage(config.languageCode);
    await _tts.setSpeechRate(config.speechRate);
    await _tts.setVolume(config.volume);
    await _tts.setPitch(config.pitch);
  }

  // ================================================================
  //  startListening()
  //  Starts the microphone. Results arrive via [onPartialResult]
  //  (live feedback) and [onFinalResult] (confirmed text).
  //
  //  WHY TWO CALLBACKS:
  //    Showing live partial results ("I hear you...") massively
  //    improves perceived responsiveness in a tourist app where
  //    users are anxious about being understood.
  // ================================================================
  Future<ServiceResult<void>> startListening({
    required void Function(String text) onFinalResult,
    void Function(String text)?         onPartialResult,
    RecognitionConfig config = const RecognitionConfig(),
  }) async {
    if (!_isReady) {
      AppLogger.error(_tag, 'startListening called before initialize().');
      return ServiceResult.fail(ServiceFailure.deviceNotSupported);
    }

    if (_stt.isListening) {
      // Already listening — stop first, then restart.
      await _stt.stop();
    }

    try {
      _emitState(ListeningState.listening);

      await _stt.listen(
        localeId:       config.localeId,
        listenFor:      config.listenFor,
        pauseFor:       config.pauseFor,
        cancelOnError:  true,
        partialResults: true, // needed to feed onPartialResult

        onResult: (SpeechRecognitionResult result) {
          AppLogger.debug(_tag,
            'STT result: "${result.recognizedWords}" '
            'final=${result.finalResult} '
            'confidence=${result.confidence.toStringAsFixed(2)}'
          );

          if (result.finalResult) {
            _emitState(ListeningState.processing);
            // Only forward if we actually got words — empty results confuse UI.
            if (result.recognizedWords.trim().isNotEmpty) {
              onFinalResult(result.recognizedWords.trim());
            }
          } else {
            onPartialResult?.call(result.recognizedWords);
          }
        },
      );

      AppLogger.info(_tag, 'Listening started [${config.localeId}]');
      return ServiceResult.ok();

    } catch (e, stack) {
      _emitState(ListeningState.idle);
      AppLogger.error(_tag, 'startListening failed.', e, stack);
      return ServiceResult.fail(ServiceFailure.unknown(e));
    }
  }

  // ================================================================
  //  stopListening()
  //  Explicit stop — call this when the user releases the mic button.
  // ================================================================
  Future<ServiceResult<void>> stopListening() async {
    try {
      await _stt.stop();
      _emitState(ListeningState.idle);
      AppLogger.info(_tag, 'Listening stopped by caller.');
      return ServiceResult.ok();
    } catch (e, stack) {
      AppLogger.error(_tag, 'stopListening failed.', e, stack);
      return ServiceResult.fail(ServiceFailure.unknown(e));
    }
  }

  // ================================================================
  //  speak()
  //  Speaks [text] aloud. Stops any in-progress speech first.
  //
  //  CONFIG PARAM:
  //    Pass a TtsConfig to change language per utterance — critical
  //    for a translation app where source/target change dynamically.
  // ================================================================
  Future<ServiceResult<void>> speak(
    String text, {
    TtsConfig config = const TtsConfig(),
  }) async {
    if (text.trim().isEmpty) {
      AppLogger.warning(_tag, 'speak() called with empty text — ignored.');
      return ServiceResult.ok(); // Not an error — caller just had nothing to say.
    }

    if (!_isTtsReady) {
      return ServiceResult.fail(ServiceFailure.deviceNotSupported);
    }

    try {
      // Stop anything currently playing before starting new speech.
      await _tts.stop();

      await _applyTtsConfig(config);
      await _tts.speak(text.trim());

      AppLogger.info(_tag, 'TTS speaking [${config.languageCode}]: "${text.trim()}"');
      return ServiceResult.ok();

    } catch (e, stack) {
      AppLogger.error(_tag, 'speak() failed.', e, stack);
      return ServiceResult.fail(ServiceFailure.unknown(e));
    }
  }

  // ================================================================
  //  stopSpeaking()
  // ================================================================
  Future<ServiceResult<void>> stopSpeaking() async {
    try {
      await _tts.stop();
      return ServiceResult.ok();
    } catch (e) {
      return ServiceResult.fail(ServiceFailure.unknown(e));
    }
  }

  // ================================================================
  //  availableLocales()
  //  Returns STT locales supported on this device.
  //  Useful for building the language-picker dropdown.
  // ================================================================
  Future<List<stt.LocaleName>> availableLocales() async {
    if (!_isReady) return [];
    try {
      return await _stt.locales();
    } catch (_) {
      return [];
    }
  }

  // ---- Getters ---- //

  bool get isListening   => _stt.isListening;
  bool get isReady       => _isReady;
  ListeningState get state => _currentState;

  // ---- Private helpers ---- //

  void _emitState(ListeningState state) {
    _currentState = state;
    if (!_listeningStateController.isClosed) {
      _listeningStateController.add(state);
    }
  }

  void _onSttError(SpeechRecognitionError error) {
    AppLogger.error(_tag, 'STT error: ${error.errorMsg} permanent=${error.permanent}');
    _emitState(ListeningState.idle);
  }

  void _onSttStatus(String status) {
    AppLogger.debug(_tag, 'STT status: $status');
    // 'done' or 'notListening' means mic closed automatically.
    if (status == 'done' || status == 'notListening') {
      _emitState(ListeningState.idle);
    }
  }

  // ================================================================
  //  dispose()
  //  ⚠️  COMMON MISTAKE: forgetting this causes mic to stay locked
  //  and audio sessions to linger — severe battery drain on iOS.
  //  Call this when the top-level widget is permanently removed.
  // ================================================================
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _stt.cancel();
    await _tts.stop();
    await _listeningStateController.close();
    AppLogger.info(_tag, 'Disposed.');
  }
}