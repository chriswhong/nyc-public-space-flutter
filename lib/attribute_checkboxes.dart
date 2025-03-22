import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AttributeOption {
  final String key;
  final IconData icon;

  const AttributeOption(this.key, this.icon);
}




class AttributeCheckboxes extends StatelessWidget {
  final Set<String> selectedDetails;
  final Set<String> selectedAmenities;
  final Set<String> selectedEquipment;
  final void Function(String category, String key, bool value) onChanged;

  const AttributeCheckboxes({
    super.key,
    required this.selectedDetails,
    required this.selectedAmenities,
    required this.selectedEquipment,
    required this.onChanged,
  });


  static const List<AttributeOption> detailOptions = [
    AttributeOption('indoor', FontAwesomeIcons.house),
    AttributeOption('accessible', FontAwesomeIcons.wheelchair),
    AttributeOption('trees', FontAwesomeIcons.tree),
    AttributeOption('grass', FontAwesomeIcons.seedling),
    AttributeOption('notable views', FontAwesomeIcons.building),
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
    AttributeOption('parking', FontAwesomeIcons.squareParking),
    AttributeOption('fountain', FontAwesomeIcons.water),
    AttributeOption('food_vendor', FontAwesomeIcons.hotdog),
    AttributeOption('splash_pad', FontAwesomeIcons.water),
  ];

  static const List<AttributeOption> equipmentOptions = [
    AttributeOption('basketball', FontAwesomeIcons.basketball),
    AttributeOption('exercise', FontAwesomeIcons.dumbbell),
    AttributeOption('handball', FontAwesomeIcons.baseball),
    AttributeOption('baseball', FontAwesomeIcons.baseballBatBall),
    AttributeOption('track', FontAwesomeIcons.personRunning),
    AttributeOption('pool', FontAwesomeIcons.waterLadder),
    AttributeOption('field', FontAwesomeIcons.futbol)
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroup(
          title: 'Details',
          options: detailOptions,
          selected: selectedDetails,
          category: 'details',
        ),
        _buildGroup(
          title: 'Amenities',
          options: amenityOptions,
          selected: selectedAmenities,
          category: 'amenities',
        ),
        _buildGroup(
          title: 'Equipment',
          options: equipmentOptions,
          selected: selectedEquipment,
          category: 'equipment',
        ),
      ],
    );
  }

  Widget _buildGroup({
  required String title,
  required List<AttributeOption> options,
  required Set<String> selected,
  required String category,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      ...options.map((option) {
        return CheckboxListTile(
          value: selected.contains(option.key),
          onChanged: (value) {
            onChanged(category, option.key, value ?? false);
          },
          title: Row(
            children: [
              Icon(option.icon, size: 20),
              const SizedBox(width: 18),
              Text(option.key.replaceAll('_', ' ').toUpperCase()),
            ],
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      }),
    ],
  );
}
}
