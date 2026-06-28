// ============================================================
// lib/screens/settings_screen.dart
// Ayarlar ekranı.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _SectionTitle('Görünüm'),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
            title: const Text('Tema', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Sistem')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Aydınlık')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Karanlık')),
              ],
              onChanged: (mode) {
                if (mode != null) settings.setThemeMode(mode);
              },
            ),
          ),
          const Divider(),
          _SectionTitle('Çeviri & Ses'),
          ListTile(
            leading: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
            title: const Text('Otomatik Seslendir', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Çeviri bitince otomatik oku', style: TextStyle(fontSize: 12)),
            trailing: Switch(
              value: settings.autoSpeak,
              activeColor: AppColors.primary,
              onChanged: (val) => settings.setAutoSpeak(val),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.speed_rounded, color: AppColors.primary),
            title: const Text('Konuşma Hızı', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Değer: ${settings.speechRate.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: settings.speechRate,
              min: 0.1,
              max: 1.0,
              activeColor: AppColors.primary,
              onChanged: (val) => settings.setSpeechRate(val),
            ),
          ),
          const Divider(),
          _SectionTitle('Hakkında'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            title: const Text('Versiyon', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Text('1.0.0', style: TextStyle(color: AppColors.gray500)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
