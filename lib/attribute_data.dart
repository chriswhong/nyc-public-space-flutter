import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AttributeOption {
  final String key;
  final IconData icon;

  const AttributeOption(this.key, this.icon);
}

class AttributeData {
  static const List<AttributeOption> detailOptions = [
    AttributeOption('indoor', FontAwesomeIcons.house),
    AttributeOption('accessible', FontAwesomeIcons.wheelchair),
    AttributeOption('trees', FontAwesomeIcons.tree),
    AttributeOption('grass', FontAwesomeIcons.seedling),
    AttributeOption('planters', FontAwesomeIcons.seedling),
    AttributeOption('scenic_views', FontAwesomeIcons.building),
    AttributeOption('temporarily_closed', FontAwesomeIcons.lock),
  ];

  static const List<AttributeOption> amenityOptions = [
    AttributeOption('restrooms', FontAwesomeIcons.toilet),
    AttributeOption('playground', FontAwesomeIcons.child),
    AttributeOption('drinking_fountain', FontAwesomeIcons.water),
    AttributeOption('dog_park', FontAwesomeIcons.dog),
    AttributeOption('seating', FontAwesomeIcons.chair),
    AttributeOption('tables', FontAwesomeIcons.table),
    AttributeOption('wifi', FontAwesomeIcons.wifi),
    AttributeOption('art', FontAwesomeIcons.palette),
    AttributeOption('monument', FontAwesomeIcons.monument),
    AttributeOption('parking', FontAwesomeIcons.squareParking),
    AttributeOption('fountain', FontAwesomeIcons.water),
    AttributeOption('food_vendor', FontAwesomeIcons.hotdog),
    AttributeOption('splash_pad', FontAwesomeIcons.water),
    AttributeOption('bike_rack', FontAwesomeIcons.bicycle)
  ];

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
