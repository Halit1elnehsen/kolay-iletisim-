// ============================================================
// lib/widgets/map/map_type_selector.dart
// Harita türü seçici (normal/uydu/arazi/karanlık).
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../config/map_tile_config.dart';

class MapTypeSelector extends StatelessWidget {
  final MapTileType currentType;
  final Function(MapTileType) onTypeChanged;
  final bool isVisible;

  const MapTypeSelector({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              'Harita Türü',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SizedBox(
            width: 200,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: MapTileType.values.map((type) => _buildOption(type)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(MapTileType type) {
    final isSelected = currentType == type;
    return InkWell(
      onTap: () => onTypeChanged(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MapTileConfig.icon(type),
              color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              MapTileConfig.label(type),
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
