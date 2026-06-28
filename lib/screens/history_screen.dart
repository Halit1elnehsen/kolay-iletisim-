// ============================================================
// lib/screens/history_screen.dart
// Çeviri geçmişi ve favoriler.
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
        appBar: AppBar(
          title: const Text('Geçmiş'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.gray500,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Tümü'),
              Tab(text: 'Favoriler'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Geçmişi Temizle',
              onPressed: () => _showClearDialog(context),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _HistoryList(isFavoritesOnly: false),
            _HistoryList(isFavoritesOnly: true),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text('Tüm çeviri geçmişini silmek istediğinize emin misiniz? (Favoriler de silinir)'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.gray600)),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.danger)),
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
              isFavoritesOnly ? Icons.favorite_border_rounded : Icons.history_rounded,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              isFavoritesOnly ? 'Henüz favori çeviriniz yok.' : 'Henüz çeviri yapmadınız.',
              style: const TextStyle(fontSize: 16, color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        // TODO: Seslendirme için provider'a entegre edilebilir
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

  // Basit bayrak eşleştirme yardımcı metodu
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
