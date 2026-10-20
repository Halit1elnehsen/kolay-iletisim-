// ============================================================
// lib/screens/taxi_screen.dart
// Taksi Modu: Dinamik GPS Konumu, En Yakın Duraklar,
// Tek Tıkla Arama, Harita Yol Tarifi ve Sesli İletişim Cümleleri.
// ============================================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/service_result.dart';
import '../models/taxi_stand.dart';
import '../services/audio_service.dart';
import '../services/location_service.dart';
import '../services/taxi_service.dart';
import '../theme/app_colors.dart';

class TaxiScreen extends StatefulWidget {
  const TaxiScreen({super.key});

  @override
  State<TaxiScreen> createState() => _TaxiScreenState();
}

class _TaxiScreenState extends State<TaxiScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  bool _isUsingFallbackLocation = false;

  List<TaxiStand> _allTaxis = [];
  List<TaxiStand> _filteredTaxis = [];
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Tümü, 1: Telefonu Olanlar, 2: Yakındakiler (< 2 km)

  // Varsayılan Referans Konum (Elazığ Merkez)
  static const double defaultLat = 38.6748;
  static const double defaultLon = 39.2225;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndTaxis();
  }

  Future<void> _fetchLocationAndTaxis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    double targetLat = defaultLat;
    double targetLon = defaultLon;

    // 1. GPS Konumunu Al
    final locResult = await LocationService.instance.getCurrentPosition();

    if (locResult.isSuccess) {
      _currentPosition = locResult.data;
      targetLat = _currentPosition!.latitude;
      targetLon = _currentPosition!.longitude;
      _isUsingFallbackLocation = false;
    } else {
      _isUsingFallbackLocation = true;
      _errorMessage = 'GPS izni alınamadı. Elazığ merkez konumu kullanılıyor.';
    }

    // 2. Taksi Duraklarını Çek
    final taxiResult = await TaxiService.instance.getNearbyTaxis(
      targetLat,
      targetLon,
      radius: 6000,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (taxiResult.isSuccess) {
          _allTaxis = taxiResult.data;
          _applyFilters();
        } else {
          _errorMessage = taxiResult.errorMessage;
        }
      });
    }
  }

  void _applyFilters() {
    List<TaxiStand> result = List.from(_allTaxis);

    // Filtre çipi
    if (_selectedFilterIndex == 1) {
      result = result.where((t) => t.hasPhone).toList();
    } else if (_selectedFilterIndex == 2) {
      result = result.where((t) => t.distance <= 2000).toList();
    }

    // Arama sorgusu
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((t) {
        return t.name.toLowerCase().contains(q) ||
            t.address.toLowerCase().contains(q) ||
            (t.phone != null && t.phone!.contains(q));
      }).toList();
    }

    setState(() {
      _filteredTaxis = result;
    });
  }

  Future<void> _callTaxi(TaxiStand taxi) async {
    if (!taxi.hasPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu durak için kayıtlı telefon numarası bulunmuyor.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await TaxiService.instance.callPhoneNumber(taxi.phone!);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arama başlatılamadı: ${taxi.phone}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLocationAndTaxis,
          color: AppColors.accentGold,
          backgroundColor: AppColors.bgDeep,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık & Durum Rozeti
                _buildHeader(),
                const SizedBox(height: 16),

                // Konum Bilgi Kartı
                _buildLocationStatusCard(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amberAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Arama & Filtreler
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 20),

                // Yakındaki Taksi Durakları Listesi
                _buildSectionTitle(
                  'En Yakın Taksi Durakları',
                  '${_filteredTaxis.length} durak bulundu',
                ),
                const SizedBox(height: 12),
                _buildTaxiList(),
                const SizedBox(height: 100), // Alt navigasyon boşluğu
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Taksi Modu',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Canlı Duraklar & Tek Tıkla Arama',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isUsingFallbackLocation
                ? Colors.amber.withValues(alpha: 0.2)
                : AppColors.accentEmerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isUsingFallbackLocation
                  ? Colors.amber.withValues(alpha: 0.4)
                  : AppColors.accentEmerald.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isUsingFallbackLocation
                    ? Icons.location_city_rounded
                    : Icons.gps_fixed_rounded,
                size: 14,
                color: _isUsingFallbackLocation
                    ? Colors.amberAccent
                    : AppColors.accentEmerald,
              ),
              const SizedBox(width: 6),
              Text(
                _isUsingFallbackLocation ? 'Elazığ Merkez' : 'Canlı GPS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isUsingFallbackLocation
                      ? Colors.amberAccent
                      : AppColors.accentEmerald,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLocationStatusCard() {
    final latText = _currentPosition != null
        ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
        : '${defaultLat.toStringAsFixed(4)}, ${defaultLon.toStringAsFixed(4)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: AppColors.accentGold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isUsingFallbackLocation ? 'Bölge Konumu' : 'Mevcut Konumunuz',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_isUsingFallbackLocation) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(Elazığ)',
                        style: TextStyle(fontSize: 12, color: Colors.amberAccent),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Koordinat: $latText',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchLocationAndTaxis,
            tooltip: 'Konumu Yenile',
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentGold,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.accentGold,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        onChanged: (val) {
          _searchQuery = val;
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Durak veya cadde adı ara...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Tümü', '📞 Telefonu Olanlar', '📍 Yakın (< 2 km)'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filters[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.accentGold,
              backgroundColor: AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppColors.accentGold : AppColors.border,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilterIndex = index;
                    _applyFilters();
                  });
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildTaxiList() {
    if (_isLoading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: AppColors.accentGold),
            SizedBox(height: 16),
            Text(
              'En yakın taksi durakları taranıyor...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_filteredTaxis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.local_taxi_outlined, size: 44, color: AppColors.accentGold.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            const Text(
              'Bu kriterlere uygun taksi durağı bulunamadı.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilterIndex = 0;
                  _applyFilters();
                });
              },
              child: const Text('Filtreleri Temizle', style: TextStyle(color: AppColors.accentGold)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredTaxis.map((taxi) => _buildTaxiCard(taxi)).toList(),
    );
  }

  Widget _buildTaxiCard(TaxiStand taxi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır: İsim, Doğrulanma Rozeti, Mesafe
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.25)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_taxi_rounded,
                    color: AppColors.accentGold,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            taxi.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (taxi.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.accentCyan,
                            size: 16,
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      taxi.address,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Canlı Mesafe Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 12,
                      color: AppColors.accentEmerald,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      taxi.distanceText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Alt Satır: Aksiyon Butonları (Tek Tıkla Ara & Haritada Aç)
          Row(
            children: [
              // Ara Butonu
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => _callTaxi(taxi),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: taxi.hasPhone
                          ? const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                            )
                          : null,
                      color: taxi.hasPhone ? null : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_in_talk_rounded,
                          size: 16,
                          color: taxi.hasPhone ? Colors.white : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            taxi.hasPhone ? taxi.phone! : 'Numara Yok',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: taxi.hasPhone ? Colors.white : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Harita Butonu
              InkWell(
                onTap: () async {
                  final ok = await TaxiService.instance.openInMaps(taxi.lat, taxi.lon);
                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Harita uygulaması açılamadı.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardHover,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.directions_rounded, size: 16, color: AppColors.accentGold),
                      SizedBox(width: 4),
                      Text(
                        'Rota',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
