// ============================================================
// lib/models/ocr_text_line.dart
// OCR API'den dönen metin satırı ve koordinatları.
// ============================================================

class OcrTextLine {
  final String text;
  final String? translatedText;
  final double left;
  final double top;
  final double width;
  final double height;

  OcrTextLine({
    required this.text,
    this.translatedText,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  OcrTextLine copyWith({
    String? text,
    String? translatedText,
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return OcrTextLine(
      text: text ?? this.text,
      translatedText: translatedText ?? this.translatedText,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
