// ============================================================
// lib/models/custom_marker.dart
// Kullanıcının eklediği özel marker modeli.
// SharedPreferences ile JSON serileştirme destekler.
// ============================================================

class CustomMarker {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final DateTime createdAt;

  const CustomMarker({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.createdAt,
  });

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  CustomMarker copyWith({String? name}) {
    return CustomMarker(
      id: id,
      name: name ?? this.name,
      lat: lat,
      lon: lon,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON'dan oluşturur. Bozuk veri varsa null döner.
  static CustomMarker? tryFromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final name = json['name'];
      final lat = json['lat'];
      final lon = json['lon'];
      final createdAt = json['createdAt'];

      if (id == null || name == null || lat == null || lon == null || createdAt == null) {
        return null;
      }

      return CustomMarker(
        id: id.toString(),
        name: name.toString(),
        lat: (lat is num) ? lat.toDouble() : double.tryParse(lat.toString()) ?? 0.0,
        lon: (lon is num) ? lon.toDouble() : double.tryParse(lon.toString()) ?? 0.0,
        createdAt: DateTime.tryParse(createdAt.toString()) ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
