// ============================================================
// lib/models/route_info.dart
// Route information model
// ============================================================

import 'package:latlong2/latlong.dart';

enum RouteMode {
  car,
  walking,
  cycling,
}

class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  final RouteMode mode;
  final String? startName;
  final String? endName;

  const RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    required this.mode,
    this.startName,
    this.endName,
  });
}
