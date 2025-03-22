import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AttributeOption {
  final String key;
  final IconData icon;

  const AttributeOption(this.key, this.icon);
}

class AttributeDisplay extends StatelessWidget {
  final List<String> details;
  final List<String> amenities;
  final List<String> equipment;

  const AttributeDisplay({
    Key? key,
    required this.details,
    required this.amenities,
    required this.equipment,
  }) : super(key: key);

  static const List<AttributeOption> detailOptions = [
    AttributeOption('indoor', FontAwesomeIcons.house),
    AttributeOption('accessible', FontAwesomeIcons.wheelchair),
    AttributeOption('trees', FontAwesomeIcons.tree),
    AttributeOption('grass', FontAwesomeIcons.pagelines),
  ];

  static const List<AttributeOption> amenityOptions = [
    AttributeOption('restroom', FontAwesomeIcons.toilet),
    AttributeOption('drinking_fountain', FontAwesomeIcons.faucet),
    AttributeOption('dog_park', FontAwesomeIcons.dog),
    AttributeOption('seating', FontAwesomeIcons.chair),
    AttributeOption('tables', FontAwesomeIcons.table),
    AttributeOption('wifi', FontAwesomeIcons.wifi),
    AttributeOption('art', FontAwesomeIcons.paintBrush),
    AttributeOption('parking', FontAwesomeIcons.squareParking),
    AttributeOption('picnic_shelter', FontAwesomeIcons.umbrellaBeach),
    AttributeOption('chess_tables', FontAwesomeIcons.chessBoard),
    AttributeOption('fountain', FontAwesomeIcons.water),
    AttributeOption('food_vendor', FontAwesomeIcons.hotdog),
  ];

  static const List<AttributeOption> equipmentOptions = [
    AttributeOption('playground', FontAwesomeIcons.children),
    AttributeOption('splash_pad', FontAwesomeIcons.water),
    AttributeOption('exercise', FontAwesomeIcons.dumbbell),
    AttributeOption('handball', FontAwesomeIcons.baseball),
    AttributeOption('basketball', FontAwesomeIcons.basketball),
    AttributeOption('baseball', FontAwesomeIcons.baseballBatBall),
    AttributeOption('track', FontAwesomeIcons.personRunning),
  ];

  List<Widget> _buildChips(
      List<String> activeKeys, List<AttributeOption> options) {
    return options
        .where((option) => activeKeys.contains(option.key))
        .map((option) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Chip(
                avatar: Icon(option.icon, size: 14, color: Colors.black),
                label: Text(option.key.replaceAll('_', ' ').toUpperCase()),
                labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
                backgroundColor: Colors.white,
                side: BorderSide.none,
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8),
            child:
                Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              children: _buildChips(details, detailOptions),
            ),
          ),
        ],
        if (amenities.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8),
            child: Text('Amenities',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              children: _buildChips(amenities, amenityOptions),
            ),
          ),
        ],
        if (equipment.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8),
            child: Text('Equipment',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              children: _buildChips(equipment, equipmentOptions),
            ),
          ),
        ],
      ],
    );
  }
}
