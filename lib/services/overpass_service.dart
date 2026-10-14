// ============================================================
// lib/services/overpass_service.dart
// OpenStreetMap Overpass API ile yakındaki yerleri bulma.
// Bounding Box desteği ile haritada gezinirken dinamik arama.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import '../models/service_result.dart';
import '../utils/app_logger.dart';
import 'location_service.dart';

class OverpassService {
  OverpassService._internal();
  static final OverpassService instance = OverpassService._internal();
  static const _tag = 'OverpassService';

  // Belirli bir mesafedeki turistik, tarihi ve kamu yerlerini getirir.
  Future<ServiceResult<List<Place>>> getNearbyPlaces(double lat, double lon, {int radius = 1000}) async {
    try {
      AppLogger.i(_tag, 'Yakındaki yerler aranıyor ($radius m): $lat, $lon');
      
      final query = '''
      [out:json][timeout:10];
      (
        node["tourism"="museum"](around:$radius,$lat,$lon);
        node["amenity"="place_of_worship"](around:$radius,$lat,$lon);
        node["tourism"="attraction"](around:$radius,$lat,$lon);
        node["historic"](around:$radius,$lat,$lon);
        way["tourism"="museum"](around:$radius,$lat,$lon);
      );
      out center 30;
      ''';

      return await _executeQuery(query, lat, lon);
    } catch (e) {
      AppLogger.w(_tag, 'Overpass hatası: $e');
      return const ServiceFailure('Yer verileri alınırken bir hata oluştu.');
    }
  }

  // Haritanın görünen bölgesindeki (Bounding Box) yerleri çeker.
  // Kullanıcı haritada gezinirken bu fonksiyon çağrılır.
  Future<ServiceResult<List<Place>>> getPlacesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    required double centerLat,
    required double centerLon,
  }) async {
    try {
      AppLogger.i(_tag, 'Bölgedeki yerler aranıyor: ($south,$west,$north,$east)');
      
      final query = '''
      [out:json][timeout:10];
      (
        node["tourism"="hotel"]($south,$west,$north,$east);
        node["tourism"="museum"]($south,$west,$north,$east);
        node["tourism"="attraction"]($south,$west,$north,$east);
        node["amenity"="restaurant"]($south,$west,$north,$east);
        node["amenity"="cafe"]($south,$west,$north,$east);
        node["amenity"="hospital"]($south,$west,$north,$east);
        node["amenity"="pharmacy"]($south,$west,$north,$east);
        node["amenity"="place_of_worship"]($south,$west,$north,$east);
        node["shop"="supermarket"]($south,$west,$north,$east);
        node["shop"="mall"]($south,$west,$north,$east);
        node["historic"]($south,$west,$north,$east);
        way["tourism"="hotel"]($south,$west,$north,$east);
        way["tourism"="museum"]($south,$west,$north,$east);
        way["shop"="mall"]($south,$west,$north,$east);
        way["amenity"="hospital"]($south,$west,$north,$east);
      );
      out center 50;
      ''';

      return await _executeQuery(query, centerLat, centerLon);
    } catch (e) {
      AppLogger.w(_tag, 'Overpass bounding box hatası: $e');
      return const ServiceFailure('Bölge verileri alınırken bir hata oluştu.');
    }
  }

  Future<ServiceResult<List<Place>>> _executeQuery(String query, double refLat, double refLon) async {
    try {
      final uri = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(query)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final elements = json['elements'] as List?;
        
        if (elements == null || elements.isEmpty) {
          return const ServiceSuccess([]);
        }

        List<Place> places = [];
        for (var el in elements) {
          final pLat = el['lat'] ?? (el['center'] != null ? el['center']['lat'] : 0.0);
          final pLon = el['lon'] ?? (el['center'] != null ? el['center']['lon'] : 0.0);
          
          if (pLat == 0.0 || pLon == 0.0) continue;
          
          // İsimsiz olanları filtrele
          final tags = el['tags'];
          if (tags == null || (tags['name'] == null && tags['name:en'] == null && tags['name:tr'] == null)) {
            continue;
          }
          
          double dist = LocationService.instance.calculateDistance(
            refLat, refLon, 
            (pLat is int) ? pLat.toDouble() : pLat, 
            (pLon is int) ? pLon.toDouble() : pLon,
          );

          places.add(Place.fromJson(el, dist));
        }

        places.sort((a, b) => a.distance.compareTo(b.distance));
        return ServiceSuccess(places);
      } else if (response.statusCode == 429 || response.statusCode == 504) {
        return const ServiceSuccess([]); // Sessizce boş döndür
      } else {
        return ServiceFailure('Yer verileri alınamadı. (${response.statusCode})');
      }
    } catch (e) {
      AppLogger.w(_tag, 'Overpass sorgu hatası: $e');
      return const ServiceSuccess([]); // Sessizce boş döndür
    }
  }
}
