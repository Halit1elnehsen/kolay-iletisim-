// ============================================================
// lib/services/geocoding_service.dart
// Koordinatı adrese çevirme (Reverse Geocoding) servisi.
// ============================================================

import 'package:geocoding/geocoding.dart';
import '../utils/app_logger.dart';

class GeocodingService {
  GeocodingService._internal();
  static final GeocodingService instance = GeocodingService._internal();
  static const _tag = 'GeocodingService';

  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      AppLogger.i(_tag, 'Adres çözümleniyor: $lat, $lon');
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(lat, lon).timeout(
        const Duration(seconds: 10),
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Örnek: "Divan Yolu Caddesi, Fatih, Istanbul"
        
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);

        if (addressParts.isEmpty) {
          return place.country; // Sadece ülke kaldıysa
        }
        return addressParts.join(', ');
      }
    } catch (e) {
      AppLogger.w(_tag, 'Geocoding hatası: $e');
    }
    return null; // Fallback to lat/lon later
  }
}
