// ============================================================
// lib/widgets/map/marker_info_window.dart
// Kullanıcı marker'ı bilgi penceresi.
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/custom_marker.dart';

class MarkerInfoWindow extends StatelessWidget {
  final CustomMarker marker;
  final Function(CustomMarker) onEdit;
  final Function(CustomMarker) onDelete;
  final Function(CustomMarker) onNavigate;
  final VoidCallback onDismiss;

  const MarkerInfoWindow({
    super.key,
    required this.marker,
    required this.onEdit,
    required this.onDelete,
    required this.onNavigate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.accentCyan.withValues(alpha: 0.1), blurRadius: 24, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık ve kapat
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.push_pin_rounded, color: AppColors.accentCyan, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${marker.lat.toStringAsFixed(5)}, ${marker.lon.toStringAsFixed(5)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white54, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Aksiyon butonları
          Row(
            children: [
              _actionBtn(Icons.edit_rounded, 'Düzenle', AppColors.accentCyan, () => onEdit(marker)),
              const SizedBox(width: 8),
              _actionBtn(Icons.route_rounded, 'Rota', const Color(0xFF10B981), () => onNavigate(marker)),
              const SizedBox(width: 8),
              _actionBtn(Icons.delete_outline_rounded, 'Sil', AppColors.accentRose, () => onDelete(marker)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
