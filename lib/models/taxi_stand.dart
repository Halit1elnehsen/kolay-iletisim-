// ============================================================
// lib/models/taxi_stand.dart
// Taksi durağı veri modeli.
// ============================================================

class TaxiStand {
  final String id;
  final String name;
  final String? phone;
  final double lat;
  final double lon;
  final String address;
  final double distance; // Metre cinsinden
  final bool isVerified;

  const TaxiStand({
    required this.id,
    required this.name,
    this.phone,
    required this.lat,
    required this.lon,
    required this.address,
    required this.distance,
    this.isVerified = false,
  });

  /// Mesafeyi kullanıcı dostu metin olarak döndürür (Örn: 450 m veya 1.8 km)
  String get distanceText {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Telefon numarası var mı?
  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;

  /// Çağrı yapılabilir temiz numara (Boşluksuz ve standart formatta)
  String get dialNumber {
    if (!hasPhone) return '';
    return phone!.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  factory TaxiStand.fromOsmJson(Map<String, dynamic> json, double distance) {
    final tags = (json['tags'] as Map<String, dynamic>?) ?? {};
    final latVal = json['lat'] ?? (json['center'] != null ? json['center']['lat'] : 0.0);
    final lonVal = json['lon'] ?? (json['center'] != null ? json['center']['lon'] : 0.0);

    final rawPhone = tags['phone'] ?? 
                     tags['contact:phone'] ?? 
                     tags['telephone'] ?? 
                     tags['contact:mobile'] ?? 
                     tags['mobile'];

    String name = tags['name'] ?? 
                  tags['name:tr'] ?? 
                  tags['name:en'] ?? 
                  tags['operator'] ?? 
                  'Taksi Durağı';

    // Adres parçalarını birleştir
    final street = tags['addr:street'];
    final housenumber = tags['addr:housenumber'];
    final suburb = tags['addr:suburb'] ?? tags['addr:district'];
    final city = tags['addr:city'];
    
    String address = '';
    if (street != null) {
      address = '$street ${housenumber != null ? 'No: $housenumber' : ''}';
    }
    if (suburb != null) {
      address = address.isEmpty ? suburb : '$address, $suburb';
    }
    if (city != null) {
      address = address.isEmpty ? city : '$address, $city';
    }
    if (address.isEmpty) {
      address = 'Konum: ${latVal.toStringAsFixed(4)}, ${lonVal.toStringAsFixed(4)}';
    }

    return TaxiStand(
      id: json['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: rawPhone?.toString(),
      lat: (latVal is int) ? latVal.toDouble() : latVal,
      lon: (lonVal is int) ? lonVal.toDouble() : lonVal,
      address: address,
      distance: distance,
      isVerified: rawPhone != null,
    );
  }
}
