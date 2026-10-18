// ============================================================
// lib/services/audio_service.dart
// Konuşma Tanıma (STT) + Metin-Ses Dönüşümü (TTS)
// Singleton — tek instance, kaynak çakışması yok.
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Completer<ServiceResult<String>>? _active;
  String _lastWords = '';

  void _finish() {
    final c = _active;
    if (c == null || c.isCompleted) return;
    _listeningStateController.add(ListeningState.idle);
    final t = _lastWords.trim();
    c.complete(
      t.isNotEmpty
          ? ServiceSuccess(t)
          : const ServiceFailure('Konuşma algılanamadı. Tekrar deneyin.'),
    );
  }

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
        onError: (error) {
          AppLogger.e(_tag, 'STT Error: ${error.errorMsg}');
          _finish();
        },
        onStatus: (status) {
          AppLogger.d(_tag, 'STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _finish();
          }
        },
      );

      // TTS başlat
      if (!kIsWeb) {
        await _tts.setSharedInstance(true);
      }
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
    if (!kIsWeb) {
      final status = await Permission.microphone.status;
      if (status.isPermanentlyDenied) {
        return const ServiceFailure(
          'Mikrofon izni kalıcı olarak reddedildi. Lütfen Ayarlar\'dan izin verin.',
        );
      }
      if (!status.isGranted) {
        final req = await Permission.microphone.request();
        if (!req.isGranted) {
          return const ServiceFailure('Mikrofon izni verilmedi.');
        }
      }
    }

    if (!_isReady) {
      await initialize();
    }
    if (!_isReady) {
      return const ServiceFailure('Ses servisi hazır değil. Google Ses Hizmetlerini kontrol edin.');
    }
    if (_stt.isListening) {
      await _stt.stop();
    }

    _lastWords = '';
    final completer = Completer<ServiceResult<String>>();
    _active = completer;

    _listeningStateController.add(ListeningState.listening);

    await _stt.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: config.localeId,
        listenFor: config.listenFor,
        pauseFor: config.pauseFor,
        cancelOnError: false,
      ),
      onResult: (SpeechRecognitionResult result) {
        _lastWords = result.recognizedWords;
        _partialTextController.add(_lastWords);

        if (result.finalResult) {
          _listeningStateController.add(ListeningState.processing);
          _finish();
        }
      },
    );

    // Timeout
    Future.delayed(config.listenFor + const Duration(seconds: 2), () {
      if (_active != null && !_active!.isCompleted) {
        _finish();
      }
    });

    final result = await completer.future;
    _listeningStateController.add(ListeningState.idle);
    return result;
  }

  Future<void> stopListening() async {
    if (_stt.isListening) {
      await _stt.stop();
    }
    _finish();
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