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
import 'package:kolay_iletisim/screens/location_screen.dart';
import 'package:kolay_iletisim/screens/taxi_screen.dart';
import 'package:kolay_iletisim/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('HomeScreen renders with required providers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // İlk kareyi oluştur
    await tester.pump();

    // HomeScreen ve ana başlık render edildi mi?
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Kolay İletişim'), findsOneWidget);
  });

  for (final taxi in [false, true]) {
    testWidgets(
      '${taxi ? 'Taxi' : 'Map'} waits for an explicit location action',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: taxi ? const TaxiScreen() : const LocationScreen()),
        );
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Konumumu kullan'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [360.0, 1440.0]) {
    testWidgets(
      'Home at width $width mounts no location screens and supports typing',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider(create: (_) => HistoryProvider()),
              ChangeNotifierProvider(create: (_) => TranslationProvider()),
            ],
            child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
          ),
        );
        await tester.pump();
        expect(find.byType(LocationScreen), findsNothing);
        expect(find.byType(TaxiScreen), findsNothing);
        await tester.enterText(find.byType(TextField), 'Merhaba dünya');
        expect(find.text('Merhaba dünya'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Yakınımda'));
        await tester.pump();
        expect(find.text('Konumumu kullan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
