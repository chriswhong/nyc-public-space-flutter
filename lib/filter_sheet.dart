import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'filters_provider.dart';
import 'geojson_provider.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  static const Map<String, String> _typeLabels = {
    'park': 'Park',
    'pops': 'POPS',
    'wpaa': 'WPAA',
    'plaza': 'Plaza',
    'stp': 'STP',
    'misc': 'Misc',
  };

  static const Map<String, Color> _typeColors = {
    'park': AppColors.parkColor,
    'pops': AppColors.popsColor,
    'wpaa': AppColors.wpaaColor,
    'plaza': AppColors.plazaColor,
    'stp': AppColors.stpColor,
    'misc': AppColors.miscColor,
  };

  static const List<Map<String, dynamic>> _amenityOptions = [
    {'key': 'restrooms', 'label': 'Restrooms', 'icon': FontAwesomeIcons.toilet},
    {'key': 'drinking_fountain', 'label': 'Water Fountain', 'icon': FontAwesomeIcons.water},
    {'key': 'seating', 'label': 'Seating', 'icon': FontAwesomeIcons.chair},
    {'key': 'tables', 'label': 'Tables', 'icon': FontAwesomeIcons.table},
    {'key': 'dog_park', 'label': 'Dog-Friendly', 'icon': FontAwesomeIcons.dog},
    {'key': 'accessible', 'label': 'Accessible', 'icon': FontAwesomeIcons.wheelchair},
  ];

  // Returns true if applying the proposed changes would still show ≥1 space.
  bool _wouldMatch(
    FiltersProvider filters,
    GeoJsonProvider geoJson, {
    Set<String>? types,
    bool? openOnly,
    Set<String>? amenities,
  }) {
    final proposed = FiltersProvider()
      ..activeTypes = types ?? Set.from(filters.activeTypes)
      ..showOpenOnly = openOnly ?? filters.showOpenOnly
      ..requiredAmenities = amenities ?? Set.from(filters.requiredAmenities);
    return proposed.apply(geoJson.features).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FiltersProvider, GeoJsonProvider>(
      builder: (context, filters, geoJson, _) {
        final matchCount = filters.apply(geoJson.features).length;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Filter Spaces',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($matchCount)',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.gray,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (filters.hasActiveFilters)
                      TextButton(
                        onPressed: filters.reset,
                        child: const Text('Clear all',
                            style: TextStyle(color: AppColors.gray)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Space type chips
                const Text(
                  'Space Type',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _typeLabels.entries.map((entry) {
                    final key = entry.key;
                    final label = entry.value;
                    final color = _typeColors[key] ?? AppColors.miscColor;
                    final isSelected = filters.activeTypes.contains(key);
                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) {
                        final next = Set<String>.from(filters.activeTypes);
                        if (val) {
                          next.add(key);
                        } else {
                          next.remove(key);
                        }
                        if (_wouldMatch(filters, geoJson, types: next)) {
                          filters.updateFilters(types: next);
                        }
                      },
                      selectedColor: color.withValues(alpha: 0.85),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.dark,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(
                          color: isSelected ? color : Colors.grey[300]!),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Open only toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide temporarily closed spaces'),
                  value: filters.showOpenOnly,
                  activeThumbColor: AppColors.dark,
                  onChanged: (val) {
                    if (_wouldMatch(filters, geoJson, openOnly: val)) {
                      filters.updateFilters(openOnly: val);
                    }
                  },
                ),

                const Divider(),
                const SizedBox(height: 8),

                // Amenity filters
                const Text(
                  'Amenities',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenityOptions.map((amenity) {
                    final key = amenity['key'] as String;
                    final label = amenity['label'] as String;
                    final icon = amenity['icon'] as FaIconData;
                    final isSelected = filters.requiredAmenities.contains(key);
                    return FilterChip(
                      avatar: FaIcon(icon, size: 11,
                          color: isSelected ? Colors.white : AppColors.gray),
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) {
                        final next = Set<String>.from(filters.requiredAmenities);
                        if (val) {
                          next.add(key);
                        } else {
                          next.remove(key);
                        }
                        if (_wouldMatch(filters, geoJson, amenities: next)) {
                          filters.updateFilters(amenities: next);
                        }
                      },
                      selectedColor: AppColors.accentDark,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.dark,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(
                          color: isSelected ? AppColors.accentDark : Colors.grey[300]!),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Show $matchCount spaces',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
