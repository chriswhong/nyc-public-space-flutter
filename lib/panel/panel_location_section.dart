import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PanelLocationSection extends StatelessWidget {
  final String? location;
  final VoidCallback onTap;

  const PanelLocationSection({
    required this.location,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (location == null || location!.isEmpty) return const SizedBox.shrink();

    return ListTile(
      leading: const FaIcon(FontAwesomeIcons.locationDot, size: 18),
      title: Text(location!, style: const TextStyle(fontSize: 14)),
      visualDensity: const VisualDensity(vertical: -4),
      onTap: onTap,
    );
  }
}