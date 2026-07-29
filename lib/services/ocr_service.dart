// ============================================================
// lib/services/ocr_service.dart
// Fotoğraftaki metni tanıyan ücretsiz OCR servisi.
// OCR.space Free API kullanır.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/service_result.dart';
import '../models/ocr_text_line.dart';
import '../utils/app_logger.dart';

class OcrService {
  OcrService._internal();
  static final OcrService instance = OcrService._internal();
  static const _tag = 'OcrService';

  // OCR.space ücretsiz API anahtarı
  static const _apiKey = 'K85674688188957';
  static const _endpoint = 'https://api.ocr.space/parse/image';

  /// Fotoğraftan metin çıkarır (base64 olarak gönderir) ve koordinatlarıyla birlikte döner.
  Future<ServiceResult<List<OcrTextLine>>> extractTextFromImage(Uint8List imageBytes) async {
    try {
      AppLogger.i(_tag, 'OCR başlatılıyor (${imageBytes.length} byte)...');

      final base64Image = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

      final response = await http.post(
        Uri.parse(_endpoint),
        body: {
          'apikey': _apiKey,
          'base64Image': base64Image,
          'language': 'tur', // Türkçe + otomatik algılama
          'isOverlayRequired': 'true', // Koordinat verisi için
          'detectOrientation': 'true',
          'scale': 'true',
          'OCREngine': '2', // Engine 2 daha iyi
        },
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['IsErroredOnProcessing'] == true) {
          final errorMsg = json['ErrorMessage']?.toString() ?? 'OCR hatası';
          AppLogger.w(_tag, 'OCR hatası: $errorMsg');
          return ServiceFailure(errorMsg);
        }

        final results = json['ParsedResults'] as List?;
        if (results == null || results.isEmpty) {
          return const ServiceFailure('Fotoğrafta metin bulunamadı.');
        }

        final firstResult = results.first;
        final textOverlay = firstResult['TextOverlay'];
        
        List<OcrTextLine> parsedLines = [];

        if (textOverlay != null && textOverlay['Lines'] != null) {
          final lines = textOverlay['Lines'] as List;
          for (var line in lines) {
            final lineText = line['LineText']?.toString().trim() ?? '';
            if (lineText.isNotEmpty) {
              final maxHeight = (line['MaxHeight'] as num?)?.toDouble() ?? 0.0;
              final minTop = (line['MinTop'] as num?)?.toDouble() ?? 0.0;
              
              // Calculate left and width from words if available
              double left = 0.0;
              double width = 0.0;
              final words = line['Words'] as List?;
              if (words != null && words.isNotEmpty) {
                left = (words.first['Left'] as num?)?.toDouble() ?? 0.0;
                final lastWord = words.last;
                final lastLeft = (lastWord['Left'] as num?)?.toDouble() ?? 0.0;
                final lastWidth = (lastWord['Width'] as num?)?.toDouble() ?? 0.0;
                width = (lastLeft + lastWidth) - left;
              }

              parsedLines.add(OcrTextLine(
                text: lineText,
                left: left,
                top: minTop,
                width: width,
                height: maxHeight,
              ));
            }
          }
        } else {
          // Geriye dönük uyumluluk: TextOverlay yoksa düz metni tek satır olarak ekle
          final parsedText = firstResult['ParsedText']?.toString().trim() ?? '';
          if (parsedText.isNotEmpty) {
             parsedLines.add(OcrTextLine(
                text: parsedText,
                left: 0, top: 0, width: 0, height: 0,
             ));
          }
        }

        if (parsedLines.isEmpty) {
          return const ServiceFailure('Fotoğrafta okunabilir metin bulunamadı.');
        }

        AppLogger.i(_tag, 'OCR başarılı: ${parsedLines.length} satır algılandı');
        return ServiceSuccess(parsedLines);
      } else {
        return ServiceFailure('OCR servisi yanıt vermedi (${response.statusCode})');
      }
    } catch (e) {
      AppLogger.e(_tag, 'OCR hatası', e);
      return ServiceFailure('Metin tanıma sırasında hata: $e');
    }
  }
}
