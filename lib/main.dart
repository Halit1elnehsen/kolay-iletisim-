// ============================================================
// lib/main.dart
// Uygulama giriş noktası — Provider'lar ve Router.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/env.dart';
import 'services/gemini_service.dart';
import 'providers/translation_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Çevre değişkenlerini (API Key) yükle
  await Env.init();
  
  // Gemini servisini başlat
  GeminiService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..loadHistory()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
      ],
      child: const SpeakBridgeApp(),
    ),
  );
}

class SpeakBridgeApp extends StatelessWidget {
  const SpeakBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'SpeakBridge',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/translate': (context) => const TranslateScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}