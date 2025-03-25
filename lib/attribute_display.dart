import 'package:flutter/material.dart';

import 'attribute_data.dart'; // Import the shared data


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


  List<Widget> _buildChips(
      List<String> activeKeys, List<AttributeOption> options) {
    return options
        .where((option) => activeKeys.contains(option.key))
        .map((option) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Chip(
                avatar: Icon(option.icon, size: 14, color: Colors.grey[700]),
                label: Text(option.key.replaceAll('_', ' ').toUpperCase()),
                labelStyle: TextStyle(fontSize: 11, color: Colors.grey[700]),
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
                icon:  Icon(Icons.add, size: 16, color: Colors.grey[700]),
                label: Text(addLabel, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
          options: AttributeData.detailOptions,
          addLabel: 'Add details',
        ),
        _buildSection(
          title: 'Amenities',
          items: amenities,
          options: AttributeData.amenityOptions,
          addLabel: 'Add amenities',
        ),
        _buildSection(
          title: 'Equipment',
          items: equipment,
          options: AttributeData.equipmentOptions,
          addLabel: 'Add equipment',
        ),
      ],
    );
  }
}
