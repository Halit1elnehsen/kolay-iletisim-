// ============================================================
// lib/screens/settings_screen.dart
// Ayarlar ekranı — Modern Glassmorphism teması.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.radialBackground),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ayarlar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _buildSectionHeader('GÖRÜNÜM & TEMA'),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.dark_mode_rounded, color: AppColors.accentCyan),
                        title: const Text('Tema Modu', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Karanlık / Aydınlık mod tercihi', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          dropdownColor: AppColors.bgLighter,
                          underline: const SizedBox(),
                          style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: ThemeMode.dark, child: Text('Karanlık')),
                            DropdownMenuItem(value: ThemeMode.light, child: Text('Aydınlık')),
                            DropdownMenuItem(value: ThemeMode.system, child: Text('Sistem')),
                          ],
                          onChanged: (mode) {
                            if (mode != null) settings.setThemeMode(mode);
                          },
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),
                    _buildSectionHeader('SES & ÇEVİRİ'),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.volume_up_rounded, color: AppColors.accentGold),
                        title: const Text('Otomatik Seslendir', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Çeviri bitince sonucu sesli oku', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        trailing: Switch(
                          value: settings.autoSpeak,
                          activeColor: AppColors.accentGold,
                          onChanged: (val) => settings.setAutoSpeak(val),
                        ),
                      ),
                      const Divider(color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            const Icon(Icons.speed_rounded, color: AppColors.accentGold, size: 20),
                            const SizedBox(width: 12),
                            const Text('Konuşma Hızı', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              '${settings.speechRate.toStringAsFixed(2)}x',
                              style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Slider(
                        value: settings.speechRate,
                        min: 0.1,
                        max: 1.0,
                        activeColor: AppColors.accentGold,
                        inactiveColor: AppColors.border,
                        onChanged: (val) => settings.setSpeechRate(val),
                      ),
                    ]),

                    const SizedBox(height: 16),
                    _buildSectionHeader('UYGULAMA HAKKINDA'),
                    _buildCard([
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded, color: AppColors.accentEmerald),
                        title: const Text('SpeakBridge (Kolay İletişim)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Turist Sesli & Görsel Tercüman', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('v1.0.0', style: TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}
