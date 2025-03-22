import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../circle_icon_button_with_label.dart';

class PanelActionButtons extends StatelessWidget {
  final VoidCallback onOpenMaps;
  final VoidCallback onEdit;
  final VoidCallback onSubmitPhoto;

  const PanelActionButtons({
    required this.onOpenMaps,
    required this.onEdit,
    required this.onSubmitPhoto,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircleIconButtonWithLabel(
          icon: FontAwesomeIcons.diamondTurnRight,
          label: 'Open in Maps',
          tooltip: 'Open in Maps',
          onPressed: onOpenMaps,
        ),
        CircleIconButtonWithLabel(
          icon: FontAwesomeIcons.pencil,
          label: 'Edit this Space',
          tooltip: 'Edit this Space',
          onPressed: onEdit,
        ),
        CircleIconButtonWithLabel(
          icon: FontAwesomeIcons.camera,
          label: 'Submit a Photo',
          tooltip: 'Submit a Photo',
          onPressed: onSubmitPhoto,
        ),
      ],
    );
  }
}