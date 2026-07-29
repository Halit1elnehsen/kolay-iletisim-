// ============================================================
// lib/services/location_service.dart
// GPS konum izni ve veri erişim servisi.
// ============================================================

import 'package:geolocator/geolocator.dart';
import '../models/service_result.dart';
import '../utils/app_logger.dart';

class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();
  static const _tag = 'LocationService';

  Future<ServiceResult<Position>> getCurrentPosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Konum servisi açık mı?
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const ServiceFailure('Konum servisleri kapalı. Lütfen ayarlardan açın.');
      }

      // İzin kontrolü
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const ServiceFailure('Konum izni reddedildi. Harita özellikleri kullanılamaz.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return const ServiceFailure(
          'Konum izni kalıcı olarak reddedilmiş. Ayarlardan uygulamanın konum iznini açmanız gerekiyor.'
        );
      } 

      AppLogger.i(_tag, 'Konum aranıyor...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      AppLogger.i(_tag, 'Konum bulundu: ${position.latitude}, ${position.longitude}');
      return ServiceSuccess(position);

    } catch (e) {
      AppLogger.e(_tag, 'Konum alma hatası', e);
      return ServiceFailure('Konum alınamadı: Zaman aşımı veya sinyal yok.');
    }
  }

  // İki nokta arası mesafe hesaplama
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
