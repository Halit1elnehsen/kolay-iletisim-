// ============================================================
// lib/models/search_result.dart
// Nominatim search result model
// ============================================================

class SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  final String type;
  final double importance;

  const SearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.type,
    required this.importance,
  });

  factory SearchResult.fromNominatimJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] as String? ?? 'Bilinmeyen Yer',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      type: json['type'] as String? ?? 'unknown',
      importance: (json['importance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
