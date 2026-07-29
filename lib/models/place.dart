// ============================================================
// lib/models/place.dart
// Overpass API'den dönen yer (mekan) modeli.
// ============================================================

class Place {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String type;
  final double distance; // metre cinsinden

  Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.type,
    required this.distance,
  });

  factory Place.fromJson(Map<String, dynamic> json, double distance) {
    final tags = json['tags'] ?? {};
    final lat = json['lat'] ?? (json['center'] != null ? json['center']['lat'] : 0.0);
    final lon = json['lon'] ?? (json['center'] != null ? json['center']['lon'] : 0.0);

    String type = 'other';
    if (tags['tourism'] != null) type = tags['tourism'];
    else if (tags['amenity'] != null) type = tags['amenity'];
    else if (tags['shop'] != null) type = 'shop_${tags['shop']}';
    else if (tags['historic'] != null) type = 'historic';

    return Place(
      id: json['id']?.toString() ?? '',
      name: tags['name'] ?? tags['name:tr'] ?? tags['name:en'] ?? 'Bilinmeyen Yer',
      lat: (lat is int) ? lat.toDouble() : lat,
      lon: (lon is int) ? lon.toDouble() : lon,
      type: type,
      distance: distance,
    );
  }
}
