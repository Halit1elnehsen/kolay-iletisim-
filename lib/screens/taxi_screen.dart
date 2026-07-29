// ============================================================
// lib/screens/taxi_screen.dart
// Taksi çağırma (Mock/Demo) ekranı.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TaxiScreen extends StatelessWidget {
  const TaxiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Taksi Modu',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(fontSize: 10, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              // Harita Görünümü (Mock)
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.bgCardHover,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.06),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 40, color: AppColors.accentGold.withOpacity(0.8)),
                    const SizedBox(height: 8),
                    const Text(
                      'Taksi Çağırma Yakında',
                      style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rotalar
              _buildDestItem('Sultanahmet (Ayasofya)', 'Tarihi Yarımada, Istanbul', '~150TL', 'A'),
              _buildDestItem('Taksim Meydanı', 'Beyoğlu, Istanbul', '~120TL', 'T'),
              _buildDestItem('İstanbul Havalimanı', 'Arnavutköy, Istanbul', '~450TL', 'P'),
              
              const SizedBox(height: 24),
              const Text(
                'Şoförle İletişim (Hazır Cümleler)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              
              _buildPhraseItem(context, 'Taksiye ihtiyacım var', 'I need a taxi', Icons.local_taxi_rounded),
              _buildPhraseItem(context, 'Taksimetre açar mısınız?', 'Please turn on the meter', Icons.money_rounded),
              _buildPhraseItem(context, 'Beni şu adrese götürün', 'Take me to this address', Icons.location_on_rounded),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestItem(String name, String detail, String price, String iconLetter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(iconLetter, style: const TextStyle(color: AppColors.accentGold, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accentEmerald)),
        ],
      ),
    );
  }

  Widget _buildPhraseItem(BuildContext context, String tr, String en, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.1)),
            ),
            child: Icon(icon, color: AppColors.accentGold, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(en, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ses çalınıyor (Demo)'), duration: Duration(seconds:1))
              );
            },
            child: Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.accentGold, Colors.orange]),
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.black, size: 18),
            ),
          )
        ],
      ),
    );
  }
}
