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
      appBar: AppBar(
        title: const Text('Sesli Çeviri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (provider.hasTranslation)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: provider.reset,
              tooltip: 'Sıfırla',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dil Seçici
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: LanguageSelector(
                source: provider.source,
                target: provider.target,
                onSourceChanged: provider.setSource,
                onTargetChanged: provider.setTarget,
                onSwap: provider.swapLanguages,
              ),
            ),

            // İçerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Metin girişi
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: provider.textController,
                            maxLines: 4,
                            minLines: 3,
                            style: const TextStyle(fontSize: 16, color: AppColors.dark),
                            decoration: InputDecoration(
                              hintText: 'Çevirmek istediğiniz metni yazın veya mikrofonu kullanın...',
                              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              suffixIcon: provider.textController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: AppColors.gray400),
                                      onPressed: () => provider.textController.clear(),
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => provider.translateText(),
                          ),
                          // Çevir butonu
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: provider.isProcessing ? null : () => provider.translateText(),
                                icon: provider.isProcessing
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.translate_rounded, size: 20),
                                label: Text(provider.isProcessing ? 'Çevriliyor...' : 'Çevir'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Durum göstergesi
                    if (provider.isListening) ...[
                      const Text(
                        'Dinleniyor...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (state.partialText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            state.partialText,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 12),
                      WaveAnimation(isActive: true, color: AppColors.primary, height: 50),
                    ],

                    // Hata
                    if (provider.hasError) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.error,
                                style: const TextStyle(color: AppColors.danger, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Çeviri sonucu
                    if (provider.hasTranslation) ...[
                      const SizedBox(height: 16),
                      TranslationCard(
                        originalText: state.recognizedText,
                        translatedText: state.translatedText,
                        sourceLabel: provider.source.label,
                        targetLabel: provider.target.label,
                        sourceFlag: provider.source.flag,
                        targetFlag: provider.target.flag,
                        onSpeakOriginal: () => provider.speakOriginal(),
                        onSpeakTranslated: () => provider.speakTranslation(),
                        onCopy: () {},
                        onFavorite: () {
                          // Geçmişe kaydet
                          final history = context.read<HistoryProvider>();
                          history.addRecord(TranslationRecord(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            originalText: state.recognizedText,
                            translatedText: state.translatedText,
                            sourceLanguageCode: provider.source.code,
                            targetLanguageCode: provider.target.code,
                            sourceLanguageLabel: provider.source.label,
                            targetLanguageLabel: provider.target.label,
                            createdAt: DateTime.now(),
                            isFavorite: true,
                          ));
                        },
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Mikrofon butonu
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    provider.isListening
                        ? 'Durdurmak için tekrar basın'
                        : 'Konuşmak için mikrofona basın',
                    style: TextStyle(
                      fontSize: 12,
                      color: provider.isListening ? AppColors.danger : AppColors.gray400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MicButton(
                    isListening: provider.isListening,
                    isProcessing: provider.isProcessing,
                    onTap: () async {
                      if (provider.isListening) {
                        await provider.stopListening();
                      } else {
                        await provider.startListening();
                        // Çeviri sonucunu otomatik kaydet
                        if (provider.hasTranslation) {
                          final history = context.read<HistoryProvider>();
                          history.addRecord(TranslationRecord(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            originalText: provider.state.recognizedText,
                            translatedText: provider.state.translatedText,
                            sourceLanguageCode: provider.source.code,
                            targetLanguageCode: provider.target.code,
                            sourceLanguageLabel: provider.source.label,
                            targetLanguageLabel: provider.target.label,
                            createdAt: DateTime.now(),
                          ));
                        }
                      }
                    },
                    size: 72,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
