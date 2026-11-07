import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../theme/app_colors.dart';
import 'translate_screen.dart';
import 'camera_screen.dart';
import 'location_screen.dart';
import 'taxi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  static const _labels = ['Çeviri', 'Kamera', 'Yakınımda', 'Taksi'];
  static const _icons = [
    Icons.translate_rounded,
    Icons.photo_camera_outlined,
    Icons.explore_outlined,
    Icons.local_taxi_outlined,
  ];

  void _select(int index) {
    if (index == _currentIndex) return;
    context.read<TranslationProvider>().reset();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Mount only the active destination. Leaving a map also stops GPS tracking.
    final screen = switch (_currentIndex) {
      1 => const CameraScreen(),
      2 => const LocationScreen(),
      3 => const TaxiScreen(),
      _ => const TranslateScreen(),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          body: Row(
            children: [
              if (wide)
                Container(
                  width: 224,
                  decoration: const BoxDecoration(
                    color: AppColors.bgDarker,
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.forum_rounded,
                            color: AppColors.accentCyan,
                            size: 32,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Kolay İletişim',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Dünyayla aynı dili konuş.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 44),
                          for (var i = 0; i < _labels.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  selected: _currentIndex == i,
                                  selectedTileColor: AppColors.accentCyan
                                      .withValues(alpha: .12),
                                  selectedColor: AppColors.accentCyan,
                                  iconColor: AppColors.textSecondary,
                                  textColor: AppColors.textSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: Icon(_icons[i]),
                                  title: Text(_labels[i]),
                                  onTap: () => _select(i),
                                ),
                              ),
                            ),
                          const Spacer(),
                          const Text(
                            'Bir konuşma.\nYeni bir bağlantı.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.6,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: screen),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: AppColors.bgDarker,
                    indicatorColor: AppColors.accentCyan.withValues(alpha: .16),
                    iconTheme: WidgetStateProperty.resolveWith(
                      (states) => IconThemeData(
                        color: states.contains(WidgetState.selected)
                            ? AppColors.accentCyan
                            : AppColors.textSecondary,
                      ),
                    ),
                    labelTextStyle: WidgetStateProperty.all(
                      const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _select,
                    destinations: List.generate(
                      4,
                      (i) => NavigationDestination(
                        icon: Icon(_icons[i]),
                        label: _labels[i],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
