// ============================================================
// lib/services/routing_service.dart
// OSRM / FOSSGIS rota hesaplama servisi.
// Araba, yürüyüş ve bisiklet rotaları desteklenir.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/service_result.dart';
import '../models/route_info.dart';
import '../utils/app_logger.dart';

class RoutingService {
  RoutingService._internal();
  static final RoutingService instance = RoutingService._internal();

  static const String _tag = 'RoutingService';
  static const int _timeoutSeconds = 15;

  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _rateLimitMs = 1100;
  bool _isRequesting = false;

  // Merkezi URL yapılandırması
  static const Map<RouteMode, String> _baseUrls = {
    RouteMode.car: 'https://router.project-osrm.org/route/v1/driving',
    RouteMode.walking: 'https://routing.openstreetmap.de/routed-foot/route/v1/driving',
    RouteMode.cycling: 'https://routing.openstreetmap.de/routed-bike/route/v1/driving',
  };

  Future<ServiceResult<RouteInfo>> getRoute(LatLng start, LatLng end, RouteMode mode) async {
    if (_isRequesting) {
      return const ServiceFailure('Bir rota isteği zaten devam ediyor. Lütfen bekleyin.');
    }
    _isRequesting = true;

    try {
      // Rate limiting
      final now = DateTime.now();
      final elapsed = now.difference(_lastRequestTime).inMilliseconds;
      if (elapsed < _rateLimitMs) {
        await Future.delayed(Duration(milliseconds: _rateLimitMs - elapsed));
      }
      _lastRequestTime = DateTime.now();

      final baseUrl = _baseUrls[mode]!;
      final url = '$baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';

      AppLogger.i(_tag, 'Rota isteniyor: $mode');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: _timeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] != 'Ok' || data['routes'] == null || (data['routes'] as List).isEmpty) {
          AppLogger.w(_tag, 'Rota bulunamadı: ${data['code']}');
          return const ServiceFailure('Bu güzergah için uygun bir rota bulunamadı.');
        }

        final route = data['routes'][0];
        final geometry = route['geometry'] as String;
        final points = _decodePolyline(geometry);

        if (points.isEmpty) {
          return const ServiceFailure('Rota verisi çözümlenemedi.');
        }

        final distanceKm = (route['distance'] as num).toDouble() / 1000.0;
        final durationMin = (route['duration'] as num).toDouble() / 60.0;

        return ServiceSuccess(RouteInfo(
          points: points,
          distanceKm: distanceKm,
          durationMin: durationMin,
          mode: mode,
        ));
      } else {
        AppLogger.e(_tag, 'HTTP hatası: ${response.statusCode}');
        return ServiceFailure('Rota sunucusu yanıt vermedi (Hata: ${response.statusCode}).');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Rota alma hatası', e);
      return const ServiceFailure('Bağlantı hatası. İnternet bağlantınızı kontrol edip tekrar deneyin.');
    } finally {
      _isRequesting = false;
    }
  }

  /// Google Encoded Polyline Algorithm ile kodlanmış rota çizgisini çözer.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> polyline = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return polyline;
  }
}
