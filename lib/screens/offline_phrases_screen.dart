// ============================================================
// lib/screens/offline_phrases_screen.dart
// İnternetsiz Hazır Kalıp Cümleler (Offline Phrase Bank).
// Selamlaşma, Acil Durumlar, Ulaşım ve Yemek kategorileri.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../services/offline_service.dart';
import '../theme/app_colors.dart';

class OfflinePhrasesScreen extends StatefulWidget {
  const OfflinePhrasesScreen({super.key});

  @override
  State<OfflinePhrasesScreen> createState() => _OfflinePhrasesScreenState();
}

class _OfflinePhrasesScreenState extends State<OfflinePhrasesScreen> {
  bool _isLoading = true;
  String _selectedCategoryId = 'greetings';
  PhraseCategory? _currentCategory;
  List<Phrase> _searchResults = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initOfflineData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initOfflineData() async {
    setState(() => _isLoading = true);
    await OfflineService.instance.loadIndex();
    await _loadCategory(_selectedCategoryId);
  }

  Future<void> _loadCategory(String categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchQuery = '';
      _searchController.clear();
      _isLoading = true;
    });

    final category = await OfflineService.instance.getCategory(categoryId);

    if (mounted) {
      setState(() {
        _currentCategory = category;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    setState(() => _searchQuery = query);
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final results = await OfflineService.instance.search(query, 'tr');
    if (mounted) {
      setState(() => _searchResults = results);
    }
  }

  Future<void> _speakText(String turkishText) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seslendiriliyor: "$turkishText"'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.accentGold.withValues(alpha: 0.9),
      ),
    );

    await AudioService.instance.speak(
      turkishText,
      const TtsConfig(languageCode: 'tr-TR', speechRate: 0.45),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metin panoya kopyalandı'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = OfflineService.instance.categoryList;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.radialBackground),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              if (_searchQuery.isEmpty) _buildCategoryTabs(categories),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.accentCyan),
                      )
                    : _buildPhraseList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Çevrimdışı Kalıplar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'İnternet bağlantısı gerekmez (Offline)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.accentEmerald),
                SizedBox(width: 4),
                Text(
                  'ÇEVRİMDIŞI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentEmerald,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Kalıp cümlelerde ara...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final id = cat['id'] as String;
          final isSelected = id == _selectedCategoryId;
          final icon = cat['icon'] as String? ?? '💬';
          final label = (cat['label'] as Map<String, dynamic>?)?['tr'] ?? id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Text(icon, style: const TextStyle(fontSize: 14)),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.accentCyan,
              backgroundColor: AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppColors.accentCyan : AppColors.border,
                ),
              ),
              onSelected: (selected) {
                if (selected) _loadCategory(id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhraseList() {
    final List<Phrase> listToDisplay = _searchQuery.isNotEmpty
        ? _searchResults
        : (_currentCategory?.phrases ?? []);

    if (listToDisplay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Cümle bulunamadı.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: listToDisplay.length,
      itemBuilder: (context, index) {
        final phrase = listToDisplay[index];
        final tr = phrase.getText('tr');
        final en = phrase.getText('en');
        final ar = phrase.getText('ar');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (en.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            en,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (ar.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ar,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Aksiyonlar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textMuted),
                        tooltip: 'Kopyala',
                        onPressed: () => _copyText(tr),
                      ),
                      InkWell(
                        onTap: () => _speakText(tr),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentCyan.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
