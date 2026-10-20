// ============================================================
// lib/services/map_launcher_service.dart
// Harita uygulamalarına yönlendirme.
// ============================================================

import 'package:url_launcher/url_launcher.dart';
import '../models/service_result.dart';
import '../utils/app_logger.dart';

class MapLauncherService {
  MapLauncherService._internal();
  static final MapLauncherService instance = MapLauncherService._internal();
  static const _tag = 'MapLauncherService';

  Future<ServiceResult<void>> launchMaps(double lat, double lon, String label) async {
    // Evrensel harita linki (Tarayıcı veya kurulu harita uygulamasında açılır)
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    
    try {
      AppLogger.i(_tag, 'Harita açılıyor: $url');
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        return const ServiceSuccess(null);
      }
      // Yedek: geo şeması
      final geoUrl = Uri.parse('geo:$lat,$lon?q=$lat,$lon($label)');
      if (await launchUrl(geoUrl, mode: LaunchMode.externalApplication)) {
        return const ServiceSuccess(null);
      }
      return const ServiceFailure('Harita uygulaması açılamadı.');
    } catch (e) {
      AppLogger.e(_tag, 'Harita başlatılamadı', e);
      return const ServiceFailure('Harita başlatılırken bir sorun oluştu.');
    }
  }
}
