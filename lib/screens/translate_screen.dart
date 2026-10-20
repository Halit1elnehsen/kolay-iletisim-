// ============================================================
// lib/screens/translate_screen.dart
// Ana çeviri ekranı — Mikrofon, çeviri kartı, metin girişi.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/gemini_service.dart';

import '../theme/app_colors.dart';
import '../widgets/wave_animation.dart';
import 'offline_phrases_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final settings = context.watch<SettingsProvider>();
    final history = context.read<HistoryProvider>();
    provider.bind(history, settings);
    final state = provider.state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Kolay İletişim',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Konuşun, anında çevirin',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Çevrimdışı Kalıplar
                        _buildHeaderIconBtn(
                          context: context,
                          icon: Icons.menu_book_rounded,
                          tooltip: 'Çevrimdışı Kalıplar',
                          color: AppColors.accentEmerald,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OfflinePhrasesScreen()),
                            );
                            provider.reset();
                          },
                        ),
                        const SizedBox(width: 8),
                        // Geçmiş
                        _buildHeaderIconBtn(
                          context: context,
                          icon: Icons.history_rounded,
                          tooltip: 'Geçmiş',
                          color: AppColors.accentCyan,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HistoryScreen()),
                            );
                            provider.reset();
                          },
                        ),
                        const SizedBox(width: 8),
                        // Ayarlar
                        _buildHeaderIconBtn(
                          context: context,
                          icon: Icons.settings_rounded,
                          tooltip: 'Ayarlar',
                          color: AppColors.accentGold,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                            provider.reset();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dil Seçici (Custom UI to match HTML)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLangBox(
                    code: provider.source.code.toUpperCase(),
                    name: provider.source.label,
                    onTap: () => _showLanguagePicker(context, isSource: true, provider: provider),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => provider.swapLanguages(),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.cyanRoseGradient,
                        boxShadow: [
                          BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 20, offset: const Offset(0,4))
                        ]
                      ),
                      child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildLangBox(
                    code: provider.target.code.toUpperCase(),
                    name: provider.target.label,
                    onTap: () => _showLanguagePicker(context, isSource: false, provider: provider),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Input Area
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x0C00F0FF), Color(0x08FFD700)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(22),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('METİN GİRİN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan, letterSpacing: 1.5)),
                        if (provider.textController.text.isNotEmpty || provider.hasTranslation)
                          GestureDetector(
                            onTap: () => provider.reset(),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: const [
                                Icon(Icons.close_rounded, size: 14, color: AppColors.accentRose),
                                SizedBox(width: 4),
                                Text('Temizle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentRose)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: provider.textController,
                      style: const TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Çevirmek istediğiniz metni yazın veya konuşun...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              // Output Area
              if (provider.hasTranslation)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x0CFFD700), Color(0x08FF4D8D)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.accentGold.withOpacity(0.05), blurRadius: 30)],
                  ),
                  padding: const EdgeInsets.all(22),
                  margin: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ÇEVİRİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Text(
                        state.translatedText,
                        style: const TextStyle(fontSize: 18, color: AppColors.accentGold, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

              // Mic & Status
              if (provider.isListening)
                WaveAnimation(isActive: true, color: AppColors.accentCyan, height: 40)
              else if (provider.hasError)
                Text(provider.error, style: const TextStyle(color: AppColors.accentRose)),
              
              const SizedBox(height: 16),
              
              // Mic Button
              GestureDetector(
                onTap: () {
                  if (provider.isListening) {
                    provider.stopListening();
                  } else {
                    provider.startListening();
                  }
                },
                child: Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(color: AppColors.accentCyan.withOpacity(0.3), width: 4),
                    boxShadow: [
                      BoxShadow(color: AppColors.accentCyan.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 8)),
                    ]
                  ),
                  child: Icon(
                    provider.isListening ? Icons.stop_rounded : Icons.mic_rounded, 
                    color: Colors.white, size: 32
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                provider.isListening ? 'Dinleniyor...' : 'Konuşmak için basın',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      icon: Icons.send_rounded,
                      label: 'Çevir',
                      isPrimary: true,
                      onTap: () => provider.translateText(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionBtn(
                      icon: Icons.volume_up_rounded,
                      label: 'Dinle',
                      isPrimary: false,
                      onTap: () => provider.speakTranslation(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangBox({
    required String code,
    required String name,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0x1A00F0FF), Color(0x1AFFD700)]),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.3), width: 2),
              boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.15), blurRadius: 20)],
            ),
            child: Center(
              child: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: AppColors.accentCyan, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, {required bool isSource, required TranslationProvider provider}) {
    final currentLang = isSource ? provider.source : provider.target;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSource ? 'Kaynak Dili Seçin' : 'Hedef Dili Seçin',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: AppLanguage.values.map((lang) {
                  final isSelected = lang == currentLang;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentCyan.withOpacity(0.12) : AppColors.glass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.accentCyan : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      leading: Text(lang.flag, style: const TextStyle(fontSize: 26)),
                      title: Text(
                        lang.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.accentCyan : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        lang.bcp47,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.accentCyan)
                          : null,
                      onTap: () {
                        if (isSource) {
                          provider.setSource(lang);
                        } else {
                          provider.setTarget(lang);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isPrimary ? null : AppColors.glass,
          border: isPrimary ? null : Border.all(color: AppColors.border),
          boxShadow: isPrimary ? [BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 20, offset: const Offset(0,4))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : AppColors.textPrimary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isPrimary ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconBtn({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
