// ============================================================
// lib/theme/app_colors.dart
// HTML'deki CSS değişkenlerinin Flutter karşılıkları.
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — İndigo
  static const primary     = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight= Color(0xFFEEF2FF);

  // Secondary — Amber
  static const secondary   = Color(0xFFF59E0B);
  static const secondaryLight = Color(0xFFFEF3C7);

  // Semantic
  static const danger      = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const success     = Color(0xFF10B981);
  static const successLight= Color(0xFFD1FAE5);
  static const warning     = Color(0xFFF59E0B);
  static const warningLight= Color(0xFFFEF3C7);

  // Feature Colors
  static const purple      = Color(0xFF9333EA);
  static const purpleLight = Color(0xFFF3E8FF);
  static const teal        = Color(0xFF0D9488);
  static const tealLight   = Color(0xFFCCFBF1);
  static const blue        = Color(0xFF2563EB);
  static const blueLight   = Color(0xFFDBEAFE);

  // Neutrals — Dark
  static const dark        = Color(0xFF1E293B);
  static const darkBg      = Color(0xFF0F172A);
  static const gray700     = Color(0xFF334155);
  static const gray600     = Color(0xFF475569);
  static const gray500     = Color(0xFF64748B);
  static const gray400     = Color(0xFF94A3B8);
  static const gray300     = Color(0xFFCBD5E1);
  static const gray200     = Color(0xFFE2E8F0);
  static const gray100     = Color(0xFFF8FAFC);
  static const white       = Color(0xFFFFFFFF);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
}
