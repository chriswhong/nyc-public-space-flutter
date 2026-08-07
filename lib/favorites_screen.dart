import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'favorites_provider.dart';
import 'colors.dart';

class FavoritesScreen extends StatelessWidget {
  final void Function(FavoriteItem) onFavoriteTap;

  const FavoritesScreen({super.key, required this.onFavoriteTap});

  Color _typeColor(String type) {
    switch (type) {
      case 'park':
        return AppColors.parkColor;
      case 'wpaa':
        return AppColors.wpaaColor;
      case 'pops':
        return AppColors.popsColor;
      case 'plaza':
        return AppColors.plazaColor;
      case 'stp':
        return AppColors.stpColor;
      default:
        return AppColors.miscColor;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'park':
        return 'Park';
      case 'wpaa':
        return 'Waterfront Public Access Area';
      case 'pops':
        return 'Privately Owned Public Space';
      case 'plaza':
        return 'Street Plaza';
      case 'stp':
        return 'Schoolyards to Playgrounds';
      default:
        return 'Miscellaneous';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: Colors.grey.shade300, height: 0.5),
        ),
      ),
      backgroundColor: AppColors.pageBackground,
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, _) {
          final favorites = provider.favorites;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.heart,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart button on a space to save it here',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FavoriteListItem(
                        item: item,
                        typeColor: _typeColor(item.type),
                        typeLabel: _typeLabel(item.type),
                        onTap: () => onFavoriteTap(item),
                        onDelete: () => provider.remove(item.firestoreId),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Swipe left on a space to remove it',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoriteListItem extends StatelessWidget {
  final FavoriteItem item;
  final Color typeColor;
  final String typeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FavoriteListItem({
    required this.item,
    required this.typeColor,
    required this.typeLabel,
    required this.onTap,
    required this.onDelete,
  });

  Future<bool?> _confirmDismiss(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove favorite?'),
        content: Text('Remove "${item.name}" from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.firestoreId),
      direction: DismissDirection.horizontal,
      confirmDismiss: (_) => _confirmDismiss(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white, size: 18),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white, size: 18),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          title: Text(
            item.name.isNotEmpty ? item.name : 'Unnamed space',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            item.borough != null ? '$typeLabel · ${item.borough}' : typeLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
