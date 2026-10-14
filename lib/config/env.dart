// ============================================================
// lib/config/env.dart
// Uygulama ortam değişkenleri ve API anahtarları.
// Prodüksiyonda --dart-define ile override edilmesi önerilir.
// ============================================================

class Env {
  Env._();

  /// OCR.space ücretsiz API anahtarı
  static const ocrSpaceApiKey = String.fromEnvironment(
    'OCR_API_KEY',
    defaultValue: 'K85674688188957',
  );
}