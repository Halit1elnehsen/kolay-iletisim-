// ============================================================
// lib/theme/app_colors.dart
// Yeni Glassmorphism (Karanlık/Neon) tema renkleri.
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Legacy Colors (for older screens like History/Settings) ---
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFFEEF2FF);
  static const secondary = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const white = Color(0xFFFFFFFF);
  static const dark = Color(0xFF1E293B);
  static const darkBg = Color(0xFF0F172A);
  static const gray100 = Color(0xFFF8FAFC);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  // ---------------------------------------------------------------

  // Backgrounds
  static const bgDeep = Color(0xFF0A0E27);
  static const bgDarker = Color(0xFF050716);
  static const bgLighter = Color(0xFF1A1F4B);
  
  static const bgCard = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const bgCardHover = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  
  // Borders
  static const border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const borderHover = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  
  // Texts
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0x99FFFFFF); // rgba(255,255,255,0.6)
  static const textMuted = Color(0x59FFFFFF); // rgba(255,255,255,0.35)
  
  // Accents (Neon)
  static const accentCyan = Color(0xFF00F0FF);
  static const accentCyanGlow = Color(0x4D00F0FF);
  
  static const accentGold = Color(0xFFFFD700);
  static const accentGoldGlow = Color(0x4DFFD700);
  
  static const accentRose = Color(0xFFFF4D8D);
  static const accentRoseGlow = Color(0x4DFF4D8D);
  
  static const accentEmerald = Color(0xFF00FFA3);
  
  // Effects
  static const glass = Color(0x08FFFFFF); // rgba(255,255,255,0.03)

  // Gradients
  static const radialBackground = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.5,
    colors: [bgLighter, bgDeep, bgDarker],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, Color(0xFF0088BB)],
  );
  
  static const cyanRoseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentRose],
  );
}
