// ============================================================
// lib/services/audio_service.dart
// Konuşma Tanıma (STT) + Metin-Ses Dönüşümü (TTS)
// Singleton — tek instance, kaynak çakışması yok.
// ============================================================

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

import '../models/service_result.dart';
import '../utils/app_logger.dart';

enum ListeningState { idle, listening, processing }

class RecognitionConfig {
  final String localeId;
  final Duration listenFor;
  final Duration pauseFor;

  const RecognitionConfig({
    this.localeId = 'ar-SA',
    this.listenFor = const Duration(seconds: 30),
    this.pauseFor  = const Duration(seconds: 3),
  });
}

class TtsConfig {
  final String languageCode;
  final double speechRate;
  final double volume;
  final double pitch;

  const TtsConfig({
    this.languageCode = 'tr-TR',
    this.speechRate   = 0.45,
    this.volume       = 1.0,
    this.pitch        = 1.0,
  });
}

class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();
  static const _tag = 'AudioService';

  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isReady = false;
  bool _isTtsReady = false;

  final _listeningStateController =
      StreamController<ListeningState>.broadcast();
  Stream<ListeningState> get listeningStateStream =>
      _listeningStateController.stream;

  final _partialTextController = StreamController<String>.broadcast();
  Stream<String> get partialTextStream => _partialTextController.stream;

  // ---- Başlatma ---- //

  Future<ServiceResult<void>> initialize() async {
    try {
      // STT başlat
      _isReady = await _stt.initialize(
        onError: (error) => AppLogger.e(_tag, 'STT Error: ${error.errorMsg}'),
        onStatus: (status) => AppLogger.d(_tag, 'STT Status: $status'),
      );

      // TTS başlat
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(true);
      _isTtsReady = true;

      AppLogger.i(_tag, 'Başlatıldı — STT: $_isReady | TTS: $_isTtsReady');
      return const ServiceSuccess(null);
    } catch (e) {
      AppLogger.e(_tag, 'Başlatma hatası', e);
      return ServiceFailure('Ses servisi başlatılamadı: $e', error: e);
    }
  }

  // ---- Konuşma Tanıma (STT) ---- //

  Future<ServiceResult<String>> startListening(RecognitionConfig config) async {
    if (!_isReady) {
      return const ServiceFailure('Ses servisi hazır değil.');
    }
    if (_stt.isListening) {
      await _stt.stop();
    }

    final completer = Completer<ServiceResult<String>>();

    _listeningStateController.add(ListeningState.listening);

    await _stt.listen(
      localeId: config.localeId,
      listenFor: config.listenFor,
      pauseFor: config.pauseFor,
      onResult: (SpeechRecognitionResult result) {
        if (result.hasConfidenceRating && result.confidence > 0) {
          _partialTextController.add(result.recognizedWords);
        }

        if (result.finalResult) {
          _listeningStateController.add(ListeningState.processing);
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            if (!completer.isCompleted) {
              completer.complete(ServiceSuccess(text));
            }
          } else {
            if (!completer.isCompleted) {
              completer.complete(
                const ServiceFailure('Konuşma tanınamadı. Tekrar deneyin.'),
              );
            }
          }
        }
      },
      cancelOnError: true,
    );

    // Timeout
    Future.delayed(config.listenFor + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        _listeningStateController.add(ListeningState.idle);
        completer.complete(
          const ServiceFailure('Zaman aşımı — konuşma algılanamadı.'),
        );
      }
    });

    final result = await completer.future;
    _listeningStateController.add(ListeningState.idle);
    return result;
  }

  Future<void> stopListening() async {
    if (_stt.isListening) {
      await _stt.stop();
      _listeningStateController.add(ListeningState.idle);
    }
  }

  // ---- Metin-Ses Dönüşümü (TTS) ---- //

  Future<ServiceResult<void>> speak(String text, TtsConfig config) async {
    if (!_isTtsReady) {
      return const ServiceFailure('TTS servisi hazır değil.');
    }
    try {
      await _tts.setLanguage(config.languageCode);
      await _tts.setSpeechRate(config.speechRate);
      await _tts.setVolume(config.volume);
      await _tts.setPitch(config.pitch);
      await _tts.speak(text);
      return const ServiceSuccess(null);
    } catch (e) {
      AppLogger.e(_tag, 'TTS hatası', e);
      return ServiceFailure('Ses çıkışı başarısız: $e', error: e);
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final langs = await _tts.getLanguages;
      return (langs as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Temizlik ---- //

  Future<void> dispose() async {
    await _stt.cancel();
    await _tts.stop();
    await _listeningStateController.close();
    await _partialTextController.close();
  }
}