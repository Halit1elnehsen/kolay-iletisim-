// ============================================================
// lib/screens/home_screen.dart
// Ana ekran — Hızlı çeviri kartı + özellikler grid + bottom nav.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/feature_card.dart';
import '../widgets/language_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: [
            _HomeTab(),
            _TranslateTabRedirect(context),
            _HistoryTabRedirect(context),
            _ProfileTabRedirect(context),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.gray200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) {
            if (i == 1) {
              Navigator.pushNamed(context, '/translate');
              return;
            }
            if (i == 2) {
              Navigator.pushNamed(context, '/history');
              return;
            }
            if (i == 3) {
              Navigator.pushNamed(context, '/settings');
              return;
            }
            setState(() => _currentTab = i);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.translate_rounded), label: 'Çeviri'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Geçmiş'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _TranslateTabRedirect(BuildContext ctx) => const SizedBox();
  Widget _HistoryTabRedirect(BuildContext ctx) => const SizedBox();
  Widget _ProfileTabRedirect(BuildContext ctx) => const SizedBox();
}

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const _Header(),
          const SizedBox(height: 24),

          // Hızlı Çeviri Kartı
          _QuickTranslateCard(),
          const SizedBox(height: 24),

          // Özellikler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Özellikler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Tümü',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeaturesGrid(),

          const SizedBox(height: 24),

          // Acil İfadeler Bölümü
          const Text(
            'Acil İfadeler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          _EmergencyPhrases(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Günaydın ☀️';
    } else if (hour < 18) {
      greeting = 'İyi günler 🌤️';
    } else {
      greeting = 'İyi akşamlar 🌙';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(fontSize: 14, color: AppColors.gray500, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        const Text(
          'SpeakBridge',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.dark, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          'Anında sesli çeviri yapın',
          style: TextStyle(fontSize: 13, color: AppColors.gray400),
        ),
      ],
    );
  }
}

class _QuickTranslateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TranslationProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekoratif daireler
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Başlık
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hızlı Çeviri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Dil seçici
                LanguageSelector(
                  source: provider.source,
                  target: provider.target,
                  onSourceChanged: provider.setSource,
                  onTargetChanged: provider.setTarget,
                  onSwap: provider.swapLanguages,
                  isOnGradient: true,
                ),
                const SizedBox(height: 20),

                // Metin girişi
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  ),
                  child: TextField(
                    controller: provider.textController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Çevirmek istediğiniz metni yazın...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.translateText(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.translate_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Çevir',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/translate'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Sesli',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: [
        FeatureCard(
          icon: Icons.mic_rounded,
          title: 'Sesli Çeviri',
          description: 'Konuş, anında çevir',
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryLight,
          onTap: () => Navigator.pushNamed(context, '/translate'),
        ),
        FeatureCard(
          icon: Icons.camera_alt_rounded,
          title: 'Fotoğraf Çeviri',
          description: 'Kameranızla çevirin',
          iconColor: AppColors.secondary,
          iconBgColor: AppColors.secondaryLight,
          badge: 'Yakında',
          onTap: () => _showComingSoon(context, 'Fotoğraf Çeviri'),
        ),
        FeatureCard(
          icon: Icons.emergency_rounded,
          title: 'Acil İfadeler',
          description: 'Hazır acil cümleler',
          iconColor: AppColors.danger,
          iconBgColor: AppColors.dangerLight,
          onTap: () => _showEmergencyDialog(context),
        ),
        FeatureCard(
          icon: Icons.map_rounded,
          title: 'Harita',
          description: 'Yakın mekanlar',
          iconColor: AppColors.blue,
          iconBgColor: AppColors.blueLight,
          badge: 'Yakında',
          onTap: () => _showComingSoon(context, 'Harita'),
        ),
        FeatureCard(
          icon: Icons.currency_exchange_rounded,
          title: 'Para Birimi',
          description: 'Döviz hesapla',
          iconColor: AppColors.success,
          iconBgColor: AppColors.successLight,
          badge: 'Yakında',
          onTap: () => _showComingSoon(context, 'Para Birimi'),
        ),
        FeatureCard(
          icon: Icons.history_rounded,
          title: 'Geçmiş',
          description: 'Önceki çeviriler',
          iconColor: AppColors.purple,
          iconBgColor: AppColors.purpleLight,
          onTap: () => Navigator.pushNamed(context, '/history'),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature yakında eklenecek! 🚀'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EmergencySheet(),
    );
  }
}

class _EmergencyPhrases extends StatelessWidget {
  final List<Map<String, String>> _phrases = const [
    {'emoji': '🆘', 'tr': 'Yardım edin!', 'en': 'Help!', 'ar': 'ساعدوني!'},
    {'emoji': '🏥', 'tr': 'Hastaneye götürün', 'en': 'Take me to hospital', 'ar': 'خذني إلى المستشفى'},
    {'emoji': '👮', 'tr': 'Polisi arayın', 'en': 'Call the police', 'ar': 'اتصل بالشرطة'},
    {'emoji': '💊', 'tr': 'İlaca ihtiyacım var', 'en': 'I need medicine', 'ar': 'أحتاج دواء'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _phrases.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dangerLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dangerLight),
        ),
        child: Row(
          children: [
            Text(p['emoji']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['tr']!,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p['en']!} • ${p['ar']!}',
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            Icon(Icons.volume_up_rounded, color: AppColors.danger.withOpacity(0.6), size: 22),
          ],
        ),
      )).toList(),
    );
  }
}

class _EmergencySheet extends StatelessWidget {
  final List<Map<String, String>> _allPhrases = const [
    {'emoji': '🆘', 'tr': 'Yardım edin!', 'en': 'Help!', 'ar': 'ساعدوني!'},
    {'emoji': '🏥', 'tr': 'Hastaneye götürün', 'en': 'Take me to hospital', 'ar': 'خذني إلى المستشفى'},
    {'emoji': '👮', 'tr': 'Polisi arayın', 'en': 'Call the police', 'ar': 'اتصل بالشرطة'},
    {'emoji': '💊', 'tr': 'İlaca ihtiyacım var', 'en': 'I need medicine', 'ar': 'أحتاج دواء'},
    {'emoji': '🚑', 'tr': 'Ambulans çağırın', 'en': 'Call an ambulance', 'ar': 'اتصل بالإسعاف'},
    {'emoji': '🔥', 'tr': 'Yangın var!', 'en': 'Fire!', 'ar': 'حريق!'},
    {'emoji': '📍', 'tr': 'Kayboldum', 'en': 'I am lost', 'ar': 'أنا ضائع'},
    {'emoji': '🏨', 'tr': 'Otelime götürün', 'en': 'Take me to my hotel', 'ar': 'خذني إلى فندقي'},
    {'emoji': '✈️', 'tr': 'Havalimanına götürün', 'en': 'Take me to the airport', 'ar': 'خذني إلى المطار'},
    {'emoji': '🚕', 'tr': 'Taksi çağırın', 'en': 'Call a taxi', 'ar': 'اتصل بسيارة أجرة'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🆘 ', style: TextStyle(fontSize: 20)),
              Text('Acil İfadeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _allPhrases.length,
              itemBuilder: (ctx, i) {
                final p = _allPhrases[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dangerLight),
                  ),
                  child: Row(
                    children: [
                      Text(p['emoji']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['tr']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
                            const SizedBox(height: 4),
                            Text(p['en']!, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                            Text(p['ar']!, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.volume_up_rounded, color: AppColors.danger, size: 22),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
