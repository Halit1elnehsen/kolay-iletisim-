// ============================================================
// lib/screens/home_screen.dart
// Ana sayfa: Custom Bottom Navigation ve IndexedStack yönetimi.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'translate_screen.dart';
import 'camera_screen.dart';
import 'location_screen.dart';
import 'taxi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TranslateScreen(),
    const CameraScreen(),
    const LocationScreen(),
    const TaxiScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep, // Arka plan deep blue
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.radialBackground),
        child: Stack(
          children: [
            // İçerik
            IndexedStack(
              index: _currentIndex,
              children: [
                const TranslateScreen(),
                _currentIndex == 1 ? const CameraScreen() : const SizedBox.shrink(),
                const LocationScreen(),
                const TaxiScreen(),
              ],
            ),
            
            // Custom Bottom Nav
            Positioned(
              left: 20, right: 20, bottom: 20,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10)),
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.translate_rounded, 'Çevir'),
                    _buildNavItem(1, Icons.camera_alt_rounded, 'Kamera'),
                    _buildNavItem(2, Icons.location_on_rounded, 'Konum'),
                    _buildNavItem(3, Icons.local_taxi_rounded, 'Taksi'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              if (isSelected) {
                return AppColors.cyanRoseGradient.createShader(bounds);
              }
              return LinearGradient(colors: [AppColors.textMuted, AppColors.textMuted]).createShader(bounds);
            },
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
            )
        ],
      ),
    );
  }
}
