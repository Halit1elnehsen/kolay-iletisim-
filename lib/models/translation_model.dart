// ============================================================
// lib/models/translation_model.dart
// Çeviri verisi modeli — geçmiş kaydı için kullanılır.
// ============================================================

class TranslationRecord {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String sourceLanguageLabel;
  final String targetLanguageLabel;
  final DateTime createdAt;
  bool isFavorite;

  TranslationRecord({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.sourceLanguageLabel,
    required this.targetLanguageLabel,
    required this.createdAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalText': originalText,
    'translatedText': translatedText,
    'sourceLanguageCode': sourceLanguageCode,
    'targetLanguageCode': targetLanguageCode,
    'sourceLanguageLabel': sourceLanguageLabel,
    'targetLanguageLabel': targetLanguageLabel,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
  };

  factory TranslationRecord.fromJson(Map<String, dynamic> json) =>
    TranslationRecord(
      id: json['id'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguageCode: json['sourceLanguageCode'] as String,
      targetLanguageCode: json['targetLanguageCode'] as String,
      sourceLanguageLabel: json['sourceLanguageLabel'] as String,
      targetLanguageLabel: json['targetLanguageLabel'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
}
