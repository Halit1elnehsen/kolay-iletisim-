// ============================================================
// lib/widgets/language_selector.dart
// Dil seçici — bayrak + isim ile görsel pill tasarımı.
// ============================================================

import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';

class LanguageSelector extends StatelessWidget {
  final AppLanguage source;
  final AppLanguage target;
  final ValueChanged<AppLanguage> onSourceChanged;
  final ValueChanged<AppLanguage> onTargetChanged;
  final VoidCallback onSwap;
  final bool isOnGradient; // gradient arka plan üzerinde mi?

  const LanguageSelector({
    super.key,
    required this.source,
    required this.target,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSwap,
    this.isOnGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LanguagePill(
          language: source,
          onChanged: onSourceChanged,
          isOnGradient: isOnGradient,
        ),
        const SizedBox(width: 12),
        _SwapButton(onTap: onSwap, isOnGradient: isOnGradient),
        const SizedBox(width: 12),
        _LanguagePill(
          language: target,
          onChanged: onTargetChanged,
          isOnGradient: isOnGradient,
        ),
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;
  final bool isOnGradient;

  const _LanguagePill({
    required this.language,
    required this.onChanged,
    required this.isOnGradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOnGradient
              ? Colors.white.withOpacity(0.2)
              : AppColors.gray100,
          borderRadius: BorderRadius.circular(100),
          border: isOnGradient
              ? null
              : Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language.flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              language.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isOnGradient ? Colors.white : AppColors.dark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isOnGradient
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dil Seçin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            ...AppLanguage.values.map((lang) => ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
              title: Text(
                lang.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                lang.bcp47,
                style: const TextStyle(color: AppColors.gray400, fontSize: 12),
              ),
              trailing: lang == language
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                onChanged(lang);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isOnGradient;

  const _SwapButton({required this.onTap, required this.isOnGradient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOnGradient
              ? Colors.white.withOpacity(0.25)
              : AppColors.primaryLight,
        ),
        child: Icon(
          Icons.swap_horiz_rounded,
          color: isOnGradient ? Colors.white : AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}
