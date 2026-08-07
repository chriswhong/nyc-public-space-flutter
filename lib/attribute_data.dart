import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AttributeOption {
  final String key;
  final FaIconData icon;

  const AttributeOption(this.key, this.icon);
}

class AttributeData {
  static const List<AttributeOption> detailOptions = [
    AttributeOption('indoor', FontAwesomeIcons.house),
    AttributeOption('trees', FontAwesomeIcons.tree),
    AttributeOption('grass', FontAwesomeIcons.seedling),
    AttributeOption('planters', FontAwesomeIcons.seedling),
    AttributeOption('scenic_views', FontAwesomeIcons.building),
    AttributeOption('temporarily_closed', FontAwesomeIcons.lock),
  ];

  // Trimmed to 8 key amenities for the micro-survey and display
  static const List<AttributeOption> amenityOptions = [
    AttributeOption('restrooms', FontAwesomeIcons.toilet),
    AttributeOption('drinking_fountain', FontAwesomeIcons.water),
    AttributeOption('seating', FontAwesomeIcons.chair),
    AttributeOption('tables', FontAwesomeIcons.table),
    AttributeOption('dog_park', FontAwesomeIcons.dog),
    AttributeOption('bike_rack', FontAwesomeIcons.bicycle),
    AttributeOption('food_vendor', FontAwesomeIcons.hotdog),
    AttributeOption('accessible', FontAwesomeIcons.wheelchair),
  ];

  // Kept for backward compatibility — not shown in new UI
  static const List<AttributeOption> equipmentOptions = [
    AttributeOption('basketball', FontAwesomeIcons.basketball),
    AttributeOption('exercise', FontAwesomeIcons.dumbbell),
    AttributeOption('handball', FontAwesomeIcons.baseball),
    AttributeOption('baseball', FontAwesomeIcons.baseballBatBall),
    AttributeOption('track', FontAwesomeIcons.personRunning),
    AttributeOption('pool', FontAwesomeIcons.waterLadder),
    AttributeOption('field', FontAwesomeIcons.futbol),
  ];
}
