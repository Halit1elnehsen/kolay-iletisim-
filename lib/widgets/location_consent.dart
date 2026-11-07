import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// No platform permission or location work takes place until the button is used.
class LocationConsent extends StatelessWidget {
  const LocationConsent({
    super.key,
    required this.taxi,
    required this.onContinue,
  });
  final bool taxi;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.bgDeep,
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    taxi ? Icons.local_taxi_outlined : Icons.explore_outlined,
                    size: 52,
                    color: AppColors.accentCyan,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  taxi ? 'Bir sonraki durağın' : 'Çevreni keşfet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  taxi
                      ? 'Yakınındaki taksi duraklarını bul, yol tarifini gör ve kolayca iletişime geç.'
                      : 'Yakınındaki restoranları, kafeleri ve ziyaret edebileceğin yerleri haritada gör.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: AppColors.bgDeep,
                    minimumSize: const Size(240, 52),
                  ),
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Konumumu kullan'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Konum izni yalnızca bu düğmeye bastığında istenir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
