// ============================================================
// lib/config/env.dart
// Konfigürasyon sabitleri.
// Ücretsiz API kullanıldığı için artık API key gerekmez.
// ============================================================

class Env {
  Env._();

  /// Gelecekte API key gerekirse buraya eklenebilir.
  static Future<void> init() async {
    // Ücretsiz API kullanıyoruz, başlatma gerekmez.
  }
}