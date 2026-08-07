import 'package:flutter/material.dart';
import 'public_space_properties.dart';

class FiltersProvider extends ChangeNotifier {
  Set<String> activeTypes = {'park', 'pops', 'wpaa', 'plaza', 'stp', 'misc'};
  bool showOpenOnly = false;
  Set<String> requiredAmenities = {};

  bool get hasActiveFilters =>
      activeTypes.length < 6 || showOpenOnly || requiredAmenities.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (activeTypes.length < 6) count++;
    if (showOpenOnly) count++;
    if (requiredAmenities.isNotEmpty) count++;
    return count;
  }

  List<PublicSpaceFeature> apply(List<PublicSpaceFeature> features) {
    return features.where((f) {
      if (!activeTypes.contains(f.properties.type)) return false;
      if (showOpenOnly && f.properties.isTemporarilyClosed) return false;
      for (final amenity in requiredAmenities) {
        final inCurated = f.properties.amenities.contains(amenity);
        final survey = f.properties.amenitySurvey[amenity];
        final communityYes = survey?['yes'] ?? 0;
        final communityNo = survey?['no'] ?? 0;
        final inCommunity = communityYes > communityNo;
        if (!inCurated && !inCommunity) return false;
      }
      return true;
    }).toList();
  }

  void updateFilters({
    Set<String>? types,
    bool? openOnly,
    Set<String>? amenities,
  }) {
    if (types != null) activeTypes = types;
    if (openOnly != null) showOpenOnly = openOnly;
    if (amenities != null) requiredAmenities = amenities;
    notifyListeners();
  }

  void reset() {
    activeTypes = {'park', 'pops', 'wpaa', 'plaza', 'stp', 'misc'};
    showOpenOnly = false;
    requiredAmenities = {};
    notifyListeners();
  }
}
