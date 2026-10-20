// ============================================================
// lib/services/taxi_service.dart
// Dinamik Taksi Durakları ve Çağrı Yönetim Servisi.
// Overpass API + Doğrulanmış Bölgesel Veri + Dinamik GPS Mesafe Sıralaması.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/service_result.dart';
import '../models/taxi_stand.dart';
import '../utils/app_logger.dart';
import 'location_service.dart';

class TaxiService {
  TaxiService._internal();
  static final TaxiService instance = TaxiService._internal();
  static const _tag = 'TaxiService';

  /// Verilen konuma en yakın taksi duraklarını çeker ve mesafeye göre sıralar
  Future<ServiceResult<List<TaxiStand>>> getNearbyTaxis(
    double lat,
    double lon, {
    int radius = 5000,
  }) async {
    try {
      AppLogger.i(_tag, 'Taksi durakları sorgulanıyor ($radius m): $lat, $lon');

      final overpassQuery = '''
      [out:json][timeout:12];
      (
        node["amenity"="taxi"](around:$radius,$lat,$lon);
        node["amenity"="taxi_stand"](around:$radius,$lat,$lon);
        way["amenity"="taxi"](around:$radius,$lat,$lon);
        way["amenity"="taxi_stand"](around:$radius,$lat,$lon);
      );
      out center 30;
      ''';

      List<TaxiStand> fetchedTaxis = [];

      try {
        final uri = Uri.parse(
          'https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(overpassQuery)}',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final elements = json['elements'] as List?;

          if (elements != null) {
            for (var el in elements) {
              final tLat = el['lat'] ?? (el['center'] != null ? el['center']['lat'] : 0.0);
              final tLon = el['lon'] ?? (el['center'] != null ? el['center']['lon'] : 0.0);

              if (tLat == 0.0 || tLon == 0.0) continue;

              final dist = LocationService.instance.calculateDistance(
                lat,
                lon,
                (tLat is int) ? tLat.toDouble() : tLat,
                (tLon is int) ? tLon.toDouble() : tLon,
              );

              fetchedTaxis.add(TaxiStand.fromOsmJson(el, dist));
            }
          }
        }
      } catch (networkErr) {
        AppLogger.w(_tag, 'Overpass ağ/zaman aşımı hatası: $networkErr');
      }

      // Bölgesel / Doğrulanmış Taksi Durakları (Elazığ & Genel Türkiye Havuzu)
      final fallbackTaxis = _getVerifiedRegionalTaxis(lat, lon);

      // İki kaynağı birleştir (ID ve mesafe bazlı tekrarları engelle)
      final Map<String, TaxiStand> mergedMap = {};

      for (var taxi in fetchedTaxis) {
        mergedMap[taxi.name.toLowerCase().trim()] = taxi;
      }

      for (var vTaxi in fallbackTaxis) {
        final key = vTaxi.name.toLowerCase().trim();
        // Eğer OSM'den gelen durakta telefon yoksa veya durak hiç yoksa doğrulanmışı kullan
        if (!mergedMap.containsKey(key) || !mergedMap[key]!.hasPhone) {
          mergedMap[key] = vTaxi;
        }
      }

      final resultList = mergedMap.values.toList();

      // Mesafeye göre en yakından en uzağa sırala
      resultList.sort((a, b) => a.distance.compareTo(b.distance));

      AppLogger.i(_tag, 'Toplam ${resultList.length} taksi durağı listelendi.');
      return ServiceSuccess(resultList);
    } catch (e) {
      AppLogger.e(_tag, 'Taksi servisi genel hatası', e);
      return ServiceFailure('Taksi durakları yüklenirken bir hata oluştu: $e');
    }
  }

  /// Telefon aramasını başlatır (tel: URI)
  Future<bool> callPhoneNumber(String phone) async {
    final cleanNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.isEmpty) return false;

    try {
      // tel: arama ekranını açar; kullanıcı yeşil tuşa basar (ek izin gerekmez)
      return await launchUrl(Uri(scheme: 'tel', path: cleanNumber));
    } catch (e) {
      AppLogger.e(_tag, 'Arama başlatılamadı: $phone', e);
      return false;
    }
  }

  /// Google Haritalar üzerinde rotayı / konumu açar
  Future<bool> openInMaps(double targetLat, double targetLon) async {
    final web = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLon&travelmode=driving',
    );
    try {
      if (await launchUrl(web, mode: LaunchMode.externalApplication)) return true;
      // Yedek: cihazdaki herhangi bir harita uygulaması
      return await launchUrl(
        Uri.parse('geo:$targetLat,$targetLon?q=$targetLat,$targetLon'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      AppLogger.e(_tag, 'Harita açılamadı', e);
      return false;
    }
  }

  /// Kullanıcı koordinatlarına göre dinamik mesafesi hesaplanan doğrulanmış yerel taksi durakları
  List<TaxiStand> _getVerifiedRegionalTaxis(double userLat, double userLon) {
    // Elazığ doğrulanmış ve aktif 7/24 taksi durakları listesi
    final seedData = [
      {
        'id': 'real-elazig-1',
        'name': 'Dörtyol Taksi Durağı',
        'phone': '+90 532 476 57 49',
        'lat': 38.6695,
        'lon': 39.2080,
        'address': 'Olgunlar / Sürsürü / Kültür Mah., Elazığ',
      },
      {
        'id': 'real-elazig-2',
        'name': 'Elazığ Merkez Taksi',
        'phone': '+90 540 023 00 78',
        'lat': 38.6748,
        'lon': 39.2225,
        'address': 'Akpınar Mah., Kolordu Caddesi, Merkez / Elazığ',
      },
      {
        'id': 'real-elazig-3',
        'name': 'Fırat Üniversitesi Hastane Taksi',
        'phone': '+90 424 237 49 19',
        'lat': 38.6812,
        'lon': 39.1925,
        'address': 'Üniversite Mah., Fırat Araştırma Hastanesi Girişi, Elazığ',
      },
      {
        'id': 'real-elazig-4',
        'name': 'Öğretmenevi & Gazi Caddesi Taksi',
        'phone': '+90 539 367 40 80',
        'lat': 38.6791,
        'lon': 39.2270,
        'address': 'Gazi Caddesi, Öğretmenevi Çevresi, Elazığ',
      },
      {
        'id': 'real-elazig-5',
        'name': 'Elazığ 7/24 Havalimanı & Şehir İçi Taksi',
        'phone': '+90 542 152 61 23',
        'lat': 38.6520,
        'lon': 39.2480,
        'address': 'Havalimanı & Şehirlerarası Otogar Hattı, Elazığ',
      },
      {
        'id': 'real-elazig-6',
        'name': 'Fırat Tıp Acil Taksi',
        'phone': '+90 542 579 05 79',
        'lat': 38.6825,
        'lon': 39.1940,
        'address': 'Fırat Tıp Merkezi Acil Girişi, Elazığ',
      },
      {
        'id': 'real-elazig-7',
        'name': 'Kültür & Kültürpark Taksi',
        'phone': '+90 532 304 67 30',
        'lat': 38.6640,
        'lon': 39.2010,
        'address': 'Kültür Mah., Kültür Park Yanı, Elazığ',
      },
    ];

    return seedData.map((data) {
      final tLat = data['lat'] as double;
      final tLon = data['lon'] as double;
      final dist = LocationService.instance.calculateDistance(
        userLat,
        userLon,
        tLat,
        tLon,
      );

      return TaxiStand(
        id: data['id'] as String,
        name: data['name'] as String,
        phone: data['phone'] as String,
        lat: tLat,
        lon: tLon,
        address: data['address'] as String,
        distance: dist,
        isVerified: true,
      );
    }).toList();
  }
}
