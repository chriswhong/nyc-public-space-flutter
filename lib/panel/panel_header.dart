import 'package:flutter/material.dart';
import '../colors.dart';

class PanelHeader extends StatelessWidget {
  final String name;
  final String type;

  const PanelHeader({
    required this.name,
    required this.type,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildPill(type),
      ],
    );
  }

  Widget _buildPill(String type) {
    String typeLabel;
    Color typeColor;

    switch (type) {
      case 'pops':
        typeLabel = 'Privately Owned Public Space';
        typeColor = AppColors.popsColor;
        break;
      case 'park':
        typeLabel = 'Park';
        typeColor = AppColors.parkColor;
        break;
      case 'wpaa':
        typeLabel = 'Waterfront Public Access Area';
        typeColor = AppColors.wpaaColor;
        break;
      case 'plaza':
        typeLabel = 'Street Plaza';
        typeColor = AppColors.plazaColor;
        break;
      case 'stp':
        typeLabel = 'Schoolyards to Playgrounds';
        typeColor = AppColors.stpColor;
        break;
      default:
        typeLabel = 'Miscellaneous';
        typeColor = AppColors.miscColor;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: typeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          typeLabel,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}