import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CircleIconButtonWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  const CircleIconButtonWithLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[300], // Light gray background
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: FaIcon(
              icon,
              size: 20,
              color: Colors.grey[800],
            ),
            onPressed: onPressed,
            tooltip: tooltip,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
