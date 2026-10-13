// map_controls.dart
// SpeakBridge Map Controls Widget

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onToggleMapType;
  final VoidCallback? onToggleCyclingLayer;
  final bool isFollowingLocation;
  final bool isCyclingLayerActive;

  const MapControls({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onToggleMapType,
    this.onToggleCyclingLayer,
    this.isFollowingLocation = false,
    this.isCyclingLayerActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          icon: Icons.layers,
          onPressed: onToggleMapType,
        ),
        if (onToggleCyclingLayer != null) ...[
          const SizedBox(height: 12),
          _buildButton(
            icon: Icons.directions_bike,
            onPressed: onToggleCyclingLayer!,
            isActive: isCyclingLayerActive,
            activeColor: AppColors.accentCyan,
          ),
        ],
        const SizedBox(height: 12),
        Container(
          decoration: _boxDecoration(),
          child: Column(
            children: [
              _buildIconButton(icon: Icons.add, onPressed: onZoomIn),
              Container(height: 1, width: 40, color: AppColors.border),
              _buildIconButton(icon: Icons.remove, onPressed: onZoomOut),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildButton(
          icon: isFollowingLocation ? Icons.my_location : Icons.location_searching,
          onPressed: onMyLocation,
          isActive: isFollowingLocation,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    Color activeColor = AppColors.accentCyan,
  }) {
    return Container(
      decoration: _boxDecoration(),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? activeColor : AppColors.textPrimary,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon),
      color: AppColors.textPrimary,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: AppColors.bgDeep.withOpacity(0.85),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
