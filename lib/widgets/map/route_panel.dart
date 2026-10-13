// ============================================================
// lib/widgets/map/route_panel.dart
// Rota planlama paneli.
// Başlangıç/varış, mod seçimi, mesafe/süre gösterimi.
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/route_info.dart';

class RoutePanel extends StatelessWidget {
  final RouteInfo? routeInfo;
  final RouteMode currentMode;
  final String? destinationName;
  final String? startName;
  final bool isCalculating;
  final Function(RouteMode) onModeChanged;
  final VoidCallback onClearRoute;
  final VoidCallback onClose;
  final bool isVisible;

  const RoutePanel({
    super.key,
    this.routeInfo,
    required this.currentMode,
    this.destinationName,
    this.startName,
    this.isCalculating = false,
    required this.onModeChanged,
    required this.onClearRoute,
    required this.onClose,
    required this.isVisible,
  });

  String _formatDuration(double minutes) {
    if (minutes < 1) return '< 1 dk';
    if (minutes < 60) return '${minutes.round()} dk';
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    if (mins == 0) return '$hours sa';
    return '$hours sa $mins dk';
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Row(
              children: [
                const Text('Rota Planı', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Başlangıç/Varış
            _locationRow(Icons.my_location_rounded, Colors.blueAccent, startName ?? 'Konumunuz'),
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Container(width: 2, height: 16, color: AppColors.border),
            ),
            _locationRow(Icons.location_on_rounded, AppColors.accentRose, destinationName ?? 'Varış noktası seçin'),
            const SizedBox(height: 20),

            // Mod butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _modeBtn(RouteMode.car, Icons.directions_car_rounded, 'Araç'),
                _modeBtn(RouteMode.walking, Icons.directions_walk_rounded, 'Yaya'),
                _modeBtn(RouteMode.cycling, Icons.directions_bike_rounded, 'Bisiklet'),
              ],
            ),

            // Hesaplanıyor göstergesi
            if (isCalculating)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan)),
                    SizedBox(width: 10),
                    Text('Rota hesaplanıyor...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),

            // Rota bilgileri
            if (routeInfo != null && !isCalculating) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Mesafe', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${routeInfo!.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: AppColors.border),
                    Column(
                      children: [
                        const Text('Süre', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(routeInfo!.durationMin),
                          style: const TextStyle(color: AppColors.accentCyan, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClearRoute,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Rotayı Temizle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String title) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _modeBtn(RouteMode mode, IconData icon, String label) {
    final sel = currentMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.accentCyan : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: sel ? AppColors.accentCyan : AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: sel ? AppColors.accentCyan : AppColors.textMuted, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
