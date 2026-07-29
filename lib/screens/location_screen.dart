// ============================================================
// lib/screens/location_screen.dart
// Google Maps benzeri tam ekran harita ekranı.
// - Kullanıcının güncel konumunu gösterir
// - Haritada gezindikçe o bölgedeki yerleri dinamik yükler
// - Pin'e tıklayınca detay kartı açılır
// - Hareket ettikçe konum pinini günceller
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/service_result.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/overpass_service.dart';
import '../services/map_launcher_service.dart';
import '../theme/app_colors.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  String _address = 'Konum aranıyor...';
  List<Place> _nearbyPlaces = [];
  Place? _selectedPlace;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();
  Timer? _searchDebounce;
  bool _isSearchingPlaces = false;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndPlaces();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startTrackingLocation() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<void> _fetchLocationAndPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final locResult = await LocationService.instance.getCurrentPosition();

    locResult.when(
      success: (position) async {
        if (!mounted) return;
        _currentPosition = position;
        _startTrackingLocation();
        
        final address = await GeocodingService.instance.getAddressFromCoordinates(
          position.latitude, position.longitude,
        );
        if (!mounted) return;
        _address = address ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        
        // İlk yükleme: yakındaki yerleri çek
        final placesResult = await OverpassService.instance.getNearbyPlaces(
          position.latitude, position.longitude, radius: 1500,
        );
        if (!mounted) return;
        placesResult.when(
          success: (places) {
            setState(() {
              _nearbyPlaces = places;
              _isLoading = false;
            });
          },
          failure: (msg) {
            setState(() {
              _isLoading = false;
            });
          },
        );
      },
      failure: (msg) {
        if (!mounted) return;
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      },
    );
  }

  // Harita hareket ettiğinde (pan/zoom) yeni bölgedeki yerleri çek
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 800), () {
        _fetchPlacesInView();
      });
    }
  }

  Future<void> _fetchPlacesInView() async {
    if (_isSearchingPlaces) return;
    _isSearchingPlaces = true;

    try {
      final bounds = _mapController.camera.visibleBounds;
      final center = _mapController.camera.center;

      final result = await OverpassService.instance.getPlacesInBounds(
        south: bounds.south,
        west: bounds.west,
        north: bounds.north,
        east: bounds.east,
        centerLat: center.latitude,
        centerLon: center.longitude,
      );

      if (!mounted) return;
      result.when(
        success: (places) {
          if (places.isNotEmpty) {
            setState(() => _nearbyPlaces = places);
          }
        },
        failure: (_) {},
      );
    } finally {
      _isSearchingPlaces = false;
    }
  }

  void _goToMyLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    }
  }

  void _showPlaceDetail(Place place) {
    setState(() => _selectedPlace = place);
  }

  void _dismissPlaceDetail() {
    setState(() => _selectedPlace = null);
  }

  void _openMapForPlace(double lat, double lon, String name) {
    MapLauncherService.instance.launchMaps(lat, lon, name).then((res) {
      res.when(
        success: (_) {},
        failure: (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
      );
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'museum': return Icons.museum_rounded;
      case 'hotel': return Icons.hotel_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'cafe': return Icons.coffee_rounded;
      case 'hospital': return Icons.local_hospital_rounded;
      case 'pharmacy': return Icons.local_pharmacy_rounded;
      case 'place_of_worship': return Icons.mosque_rounded;
      case 'attraction': return Icons.photo_camera_rounded;
      case 'historic': return Icons.account_balance_rounded;
      default:
        if (type.startsWith('shop_')) return Icons.shopping_cart_rounded;
        return Icons.place_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'museum': return AppColors.accentRose;
      case 'hotel': return const Color(0xFF8B5CF6);
      case 'restaurant': case 'cafe': return const Color(0xFFF59E0B);
      case 'hospital': case 'pharmacy': return const Color(0xFFEF4444);
      case 'place_of_worship': return AppColors.accentCyan;
      case 'attraction': return const Color(0xFF10B981);
      case 'historic': return const Color(0xFFEC4899);
      default:
        if (type.startsWith('shop_')) return const Color(0xFF3B82F6);
        return AppColors.accentCyan;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'museum': return 'Müze';
      case 'hotel': return 'Otel';
      case 'restaurant': return 'Restoran';
      case 'cafe': return 'Kafe';
      case 'hospital': return 'Hastane';
      case 'pharmacy': return 'Eczane';
      case 'place_of_worship': return 'İbadet Yeri';
      case 'attraction': return 'Turistik Yer';
      case 'historic': return 'Tarihi Yer';
      default:
        if (type.startsWith('shop_')) return 'Market';
        return 'Yer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
        : _errorMessage != null && _currentPosition == null
          ? _buildErrorView()
          : _buildMapView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.accentRose, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchLocationAndPlaces,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // ─── 1. TAM EKRAN HARİTA ───
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapEvent: _onMapEvent,
            onTap: (_, __) => _dismissPlaceDetail(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.speakbridge.app',
            ),
            MarkerLayer(
              markers: [
                // Kullanıcı konumu (mavi halka + beyaz nokta)
                if (_currentPosition != null)
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4).withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4285F4), width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4285F4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Yakındaki yerler pinleri
                ..._nearbyPlaces.map((p) {
                  final color = _colorForType(p.type);
                  final icon = _iconForType(p.type);
                  final isSelected = _selectedPlace?.id == p.id;
                  return Marker(
                    point: LatLng(p.lat, p.lon),
                    width: isSelected ? 52 : 42,
                    height: isSelected ? 52 : 42,
                    child: GestureDetector(
                      onTap: () => _showPlaceDetail(p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: isSelected ? 3 : 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: isSelected ? 12 : 6,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Icon(icon, size: isSelected ? 24 : 18, color: isSelected ? Colors.white : color),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // ─── 2. ÜST ADRES BARI ───
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep.withOpacity(0.92),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4285F4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _address,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isSearchingPlaces)
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                  ),
              ],
            ),
          ),
        ),

        // ─── 3. SAĞDA BUTONLAR (Konumuma Git + Yenile) ───
        Positioned(
          right: 16,
          bottom: (_selectedPlace != null ? 220 : 16) + MediaQuery.of(context).padding.bottom + 80,
          child: Column(
            children: [
              _buildCircleButton(
                icon: Icons.my_location_rounded,
                color: const Color(0xFF4285F4),
                onTap: _goToMyLocation,
              ),
              const SizedBox(height: 12),
              _buildCircleButton(
                icon: Icons.refresh_rounded,
                color: AppColors.accentCyan,
                onTap: _fetchPlacesInView,
              ),
            ],
          ),
        ),

        // ─── 4. ALT DETAY KARTI (Pin'e tıklayınca) ───
        if (_selectedPlace != null)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 80,
            left: 16,
            right: 16,
            child: _buildPlaceCard(_selectedPlace!),
          ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: AppColors.bgDeep.withOpacity(0.92),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    final color = _colorForType(place.type);
    final icon = _iconForType(place.type);
    final label = _labelForType(place.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 30, spreadRadius: 2),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              // İkon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              // İsim & Tür
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.directions_walk_rounded, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          '${place.distance < 1000 ? '${place.distance.toInt()}m' : '${(place.distance / 1000).toStringAsFixed(1)}km'}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Kapat butonu
              GestureDetector(
                onTap: _dismissPlaceDetail,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white54, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Yol Tarifi Butonu
          GestureDetector(
            onTap: () => _openMapForPlace(place.lat, place.lon, place.name),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 12),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Yol Tarifi Al',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
