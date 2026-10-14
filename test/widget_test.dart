// ============================================================
// test/widget_test.dart
// Temel smoke test — HomeScreen ve Provider entegrasyonu.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kolay_iletisim/providers/settings_provider.dart';
import 'package:kolay_iletisim/providers/history_provider.dart';
import 'package:kolay_iletisim/providers/translation_provider.dart';
import 'package:kolay_iletisim/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders with required providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // İlk kareyi oluştur
    await tester.pump();

    // HomeScreen ve ana başlık render edildi mi?
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Kolay İletişim'), findsOneWidget);
  });
}
