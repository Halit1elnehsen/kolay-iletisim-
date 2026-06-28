// ============================================================
// lib/widgets/translation_card.dart
// Çeviri sonuç kartı — orijinal + çevrilmiş metin, ses butonu.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class TranslationCard extends StatelessWidget {
  final String originalText;
  final String translatedText;
  final String sourceLabel;
  final String targetLabel;
  final String sourceFlag;
  final String targetFlag;
  final VoidCallback? onSpeakOriginal;
  final VoidCallback? onSpeakTranslated;
  final VoidCallback? onCopy;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const TranslationCard({
    super.key,
    required this.originalText,
    required this.translatedText,
    required this.sourceLabel,
    required this.targetLabel,
    required this.sourceFlag,
    required this.targetFlag,
    this.onSpeakOriginal,
    this.onSpeakTranslated,
    this.onCopy,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Orijinal metin
          _TextSection(
            flag: sourceFlag,
            label: sourceLabel,
            text: originalText,
            onSpeak: onSpeakOriginal,
            backgroundColor: AppColors.gray100,
            isTop: true,
          ),
          // Ayırıcı
          Container(
            height: 1,
            color: AppColors.gray200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Çevrilmiş metin
          _TextSection(
            flag: targetFlag,
            label: targetLabel,
            text: translatedText,
            onSpeak: onSpeakTranslated,
            backgroundColor: AppColors.primaryLight.withOpacity(0.3),
            isTop: false,
            textColor: AppColors.primary,
          ),
          // Alt butonlar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _IconBtn(
                  icon: Icons.copy_rounded,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: translatedText));
                    onCopy?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kopyalandı!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Kopyala',
                ),
                const SizedBox(width: 8),
                if (onFavorite != null)
                  _IconBtn(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    onTap: onFavorite!,
                    color: isFavorite ? AppColors.danger : null,
                    tooltip: 'Favori',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String flag;
  final String label;
  final String text;
  final VoidCallback? onSpeak;
  final Color backgroundColor;
  final bool isTop;
  final Color? textColor;

  const _TextSection({
    required this.flag,
    required this.label,
    required this.text,
    this.onSpeak,
    required this.backgroundColor,
    required this.isTop,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(20) : Radius.zero,
          bottom: isTop ? Radius.zero : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppColors.gray500,
                ),
              ),
              const Spacer(),
              if (onSpeak != null)
                GestureDetector(
                  onTap: onSpeak,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (textColor ?? AppColors.gray400).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: textColor ?? AppColors.gray500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text.isEmpty ? '...' : text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor ?? AppColors.dark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color ?? AppColors.gray500),
        ),
      ),
    );
  }
}
