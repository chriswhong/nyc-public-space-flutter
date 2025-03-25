import 'package:flutter/material.dart';
import './attribute_data.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroup(
          title: 'Details',
          options: AttributeData.detailOptions,
          selected: selectedDetails,
          category: 'details',
        ),
        _buildGroup(
          title: 'Amenities',
          options: AttributeData.amenityOptions,
          selected: selectedAmenities,
          category: 'amenities',
        ),
        _buildGroup(
          title: 'Equipment',
          options: AttributeData.equipmentOptions,
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
