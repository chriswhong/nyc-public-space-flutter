import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../circle_icon_button_with_label.dart';

class PanelActionButtons extends StatelessWidget {
  final VoidCallback onOpenMaps;
  final VoidCallback onEdit;
  final VoidCallback onSubmitPhoto;
  final VoidCallback onToggleFavorite;
  final bool isFavorited;

  const PanelActionButtons({
    required this.onOpenMaps,
    required this.onEdit,
    required this.onSubmitPhoto,
    required this.onToggleFavorite,
    required this.isFavorited,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
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
            _FavoriteButton(
              isFavorited: isFavorited,
              onPressed: onToggleFavorite,
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback onPressed;

  const _FavoriteButton({required this.isFavorited, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isFavorited ? Colors.red.shade50 : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: FaIcon(
              isFavorited
                  ? FontAwesomeIcons.solidHeart
                  : FontAwesomeIcons.heart,
              size: 20,
              color: isFavorited ? Colors.red.shade400 : Colors.grey[800],
            ),
            onPressed: onPressed,
            tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isFavorited ? 'Favorited' : 'Favorite',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
