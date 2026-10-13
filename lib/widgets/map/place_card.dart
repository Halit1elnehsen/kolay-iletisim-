// ============================================================
// lib/widgets/map/place_card.dart
// POI (ilgi noktası) detay kartı.
// Mevcut LocationScreen'den çıkarılmış, rota oluşturma eklendi.
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/place.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final Function(Place) onNavigate;
  final Function(Place) onCreateRoute;
  final VoidCallback onDismiss;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onNavigate,
    required this.onCreateRoute,
    required this.onDismiss,
  });

  // Orijinal LocationScreen'deki ikon eşlemesi korunuyor
  IconData _iconForType(String type) {
    switch (type) {
      case 'museum': return Icons.museum_rounded;
      case 'hotel': return Icons.hotel_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'cafe': return Icons.coffee_rounded;
      case 'hospital': return Icons.local_hospital_rounded;
      case 'pharmacy': return Icons.local_pharmacy_rounded;
      case 'place_of_worship': return Icons.mosque_rounded;
      case 'attraction': return Icons.photo_camera_rounded;
      case 'historic': return Icons.account_balance_rounded;
      default:
        if (type.startsWith('shop_')) return Icons.shopping_cart_rounded;
        return Icons.place_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'museum': return AppColors.accentRose;
      case 'hotel': return const Color(0xFF8B5CF6);
      case 'restaurant': case 'cafe': return const Color(0xFFF59E0B);
      case 'hospital': case 'pharmacy': return const Color(0xFFEF4444);
      case 'place_of_worship': return AppColors.accentCyan;
      case 'attraction': return const Color(0xFF10B981);
      case 'historic': return const Color(0xFFEC4899);
      default:
        if (type.startsWith('shop_')) return const Color(0xFF3B82F6);
        return AppColors.accentCyan;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'museum': return 'Müze';
      case 'hotel': return 'Otel';
      case 'restaurant': return 'Restoran';
      case 'cafe': return 'Kafe';
      case 'hospital': return 'Hastane';
      case 'pharmacy': return 'Eczane';
      case 'place_of_worship': return 'İbadet Yeri';
      case 'attraction': return 'Turistik Yer';
      case 'historic': return 'Tarihi Yer';
      default:
        if (type.startsWith('shop_')) return 'Market';
        return 'Yer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(place.type);
    final icon = _iconForType(place.type);
    final label = _labelForType(place.type);
    final distStr = place.distance < 1000
        ? '${place.distance.toInt()}m'
        : '${(place.distance / 1000).toStringAsFixed(1)}km';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.directions_walk_rounded, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(distStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onCreateRoute(place),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route_rounded, color: color, size: 16),
                        const SizedBox(width: 6),
                        Text('Rota Oluştur', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onNavigate(place),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Yol Tarifi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
