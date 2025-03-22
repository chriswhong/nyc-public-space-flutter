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
  final VoidCallback? onEditTap;

  const AttributeDisplay({
    Key? key,
    required this.details,
    required this.amenities,
    required this.equipment,
    this.onEditTap,
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

  
  Widget _buildSection({
    required String title,
    required List<String> items,
    required List<AttributeOption> options,
    required String addLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (items.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              runAlignment: WrapAlignment.start,
              children: _buildChips(items, options),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onEditTap,
                icon: const Icon(Icons.add, size: 16),
                label: Text(addLabel, style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // <-- Important
      children: [
        _buildSection(
          title: 'Details',
          items: details,
          options: detailOptions,
          addLabel: 'Add details',
        ),
        _buildSection(
          title: 'Amenities',
          items: amenities,
          options: amenityOptions,
          addLabel: 'Add amenities',
        ),
        _buildSection(
          title: 'Equipment',
          items: equipment,
          options: equipmentOptions,
          addLabel: 'Add equipment',
        ),
      ],
    );
  }
}
