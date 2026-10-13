// ============================================================
// lib/widgets/map/map_search_bar.dart
// Arama çubuğu ve sonuç listesi widget'ı.
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/search_result.dart';

class MapSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(SearchResult) onResultSelected;
  final VoidCallback onClear;
  final List<SearchResult> results;
  final bool isSearching;
  final List<String> searchHistory;
  final Function(String)? onHistoryTap;

  const MapSearchBar({
    super.key,
    required this.onSearch,
    required this.onResultSelected,
    required this.onClear,
    this.results = const [],
    this.isSearching = false,
    this.searchHistory = const [],
    this.onHistoryTap,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearField() {
    _controller.clear();
    widget.onClear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showHistory = _isFocused && _controller.text.isEmpty && widget.searchHistory.isNotEmpty;
    final showResults = widget.results.isNotEmpty;
    final showDropdown = _isFocused && (showHistory || showResults || widget.isSearching);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arama kutusu
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgDeep.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Adres, şehir veya mekan arayın...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: _clearField,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (val) {
              setState(() {});
              widget.onSearch(val);
            },
          ),
        ),

        // Dropdown (geçmiş veya sonuçlar)
        if (showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.bgDeep.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accentCyan,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        if (showHistory && !showResults) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Text(
                              'Son Aramalar',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ...widget.searchHistory.map((h) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 18),
                                title: Text(h, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                onTap: () {
                                  _controller.text = h;
                                  _controller.selection = TextSelection.fromPosition(
                                    TextPosition(offset: h.length),
                                  );
                                  widget.onHistoryTap?.call(h) ?? widget.onSearch(h);
                                },
                              )),
                        ],
                        if (showResults)
                          ...widget.results.map((result) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.location_on_rounded, color: AppColors.accentCyan, size: 18),
                                title: Text(
                                  result.displayName,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  _controller.text = result.displayName.split(',').first;
                                  _focusNode.unfocus();
                                  widget.onResultSelected(result);
                                },
                              )),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}
