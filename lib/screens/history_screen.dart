// ============================================================
// lib/screens/history_screen.dart
// Çeviri geçmişi ve favoriler — Modern Glassmorphism teması.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/translation_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.radialBackground),
          child: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
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
                        'Çeviri Geçmişi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.accentRose),
                        tooltip: 'Geçmişi Temizle',
                        onPressed: () => _showClearDialog(context),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppColors.primaryGradient,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'Tümü'),
                      Tab(text: 'Favoriler ⭐'),
                    ],
                  ),
                ),

                const Expanded(
                  child: TabBarView(
                    children: [
                      _HistoryList(isFavoritesOnly: false),
                      _HistoryList(isFavoritesOnly: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Geçmişi Temizle',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tüm çeviri geçmişini silmek istediğinize emin misiniz? (Favoriler de silinir)',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final bool isFavoritesOnly;

  const _HistoryList({required this.isFavoritesOnly});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final records = isFavoritesOnly ? history.favorites : history.records;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFavoritesOnly ? Icons.star_border_rounded : Icons.history_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isFavoritesOnly ? 'Henüz favori çeviriniz yok.' : 'Henüz çeviri kaydı bulunmuyor.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return TranslationCard(
          originalText: record.originalText,
          translatedText: record.translatedText,
          sourceLabel: record.sourceLanguageLabel,
          targetLabel: record.targetLanguageLabel,
          sourceFlag: _getFlag(record.sourceLanguageCode),
          targetFlag: _getFlag(record.targetLanguageCode),
          isFavorite: record.isFavorite,
          onFavorite: () => history.toggleFavorite(record.id),
        );
      },
    );
  }

  String _getFlag(String code) {
    switch (code) {
      case 'ar': return '🇸🇦';
      case 'en': return '🇺🇸';
      case 'tr': return '🇹🇷';
      case 'de': return '🇩🇪';
      case 'fr': return '🇫🇷';
      case 'es': return '🇪🇸';
      case 'ru': return '🇷🇺';
      case 'zh': return '🇨🇳';
      case 'ja': return '🇯🇵';
      default: return '🌐';
    }
  }
}
