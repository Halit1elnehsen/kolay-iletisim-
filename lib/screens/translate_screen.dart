// ============================================================
// lib/screens/translate_screen.dart
// Ana çeviri ekranı — Mikrofon, çeviri kartı, metin girişi.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../providers/history_provider.dart';
import '../models/translation_model.dart';
import '../services/translation_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/mic_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation_card.dart';
import '../widgets/wave_animation.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();
    final state = provider.state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 32),
                child: Column(
                  children: [
                    Text(
                      'Kolay İletişim',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, // In real app we might use ShaderMask for gradient text
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Konuşun, anında çevirin',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Dil Seçici (Custom UI to match HTML)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLangBox(provider.source.code.toUpperCase(), provider.source.label),
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
                  _buildLangBox(provider.target.code.toUpperCase(), provider.target.label),
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
                    const Text('METİN GİRİN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan, letterSpacing: 1.5)),
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

  Widget _buildLangBox(String code, String name) {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0x1A00F0FF), Color(0x1AFFD700)]),
            border: Border.all(color: AppColors.accentCyan.withOpacity(0.2), width: 2),
            boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Center(
            child: Text(code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
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
}
