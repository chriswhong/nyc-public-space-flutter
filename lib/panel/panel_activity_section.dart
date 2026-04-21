import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../activity_feed_screen.dart';
import '../colors.dart';
import '../space_activity_screen.dart';

class PanelActivitySection extends StatefulWidget {
  final String spaceId;
  final String spaceName;

  const PanelActivitySection({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  State<PanelActivitySection> createState() => _PanelActivitySectionState();
}

class _PanelActivitySectionState extends State<PanelActivitySection> {
  List<ActivityItem> _items = [];
  bool _loading = true;

  StreamSubscription<QuerySnapshot>? _imagesSub;
  StreamSubscription<QuerySnapshot>? _editsSub;
  List<ActivityItem> _imageItems = [];
  List<ActivityItem> _editItems = [];

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant PanelActivitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) {
      _imageItems = [];
      _editItems = [];
      setState(() => _loading = true);
      _imagesSub?.cancel();
      _editsSub?.cancel();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _imagesSub?.cancel();
    _editsSub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    final db = FirebaseFirestore.instance;

    _imagesSub = db
        .collection('images')
        .where('spaceId', isEqualTo: widget.spaceId)
        .where('status', isEqualTo: 'approved')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      _imageItems = snap.docs.map((doc) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp?;
        return ActivityItem(
          id: doc.id,
          type: 'photo',
          spaceId: data['spaceId'] as String? ?? '',
          userId: data['userId'] as String? ?? '',
          username: data['username'] as String? ?? 'someone',
          timestamp: ts?.toDate() ?? DateTime.now(),
        );
      }).toList();
      _rebuild();
    });

    _editsSub = db
        .collection('public-spaces-edits')
        .where('spaceId', isEqualTo: widget.spaceId)
        .where('status', isEqualTo: 'approved')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      _editItems = snap.docs.map((doc) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp?;
        return ActivityItem(
          id: doc.id,
          type: 'edit',
          spaceId: data['spaceId'] as String? ?? '',
          userId: data['userId'] as String? ?? '',
          username: data['userName'] as String? ?? 'someone',
          timestamp: ts?.toDate() ?? DateTime.now(),
        );
      }).toList();
      _rebuild();
    });
  }

  void _rebuild() {
    final merged = [..._imageItems, ..._editItems];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _items = merged;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No approved contributions yet.',
          style: TextStyle(color: AppColors.gray, fontSize: 13),
        ),
      );
    }

    final preview = _items.take(5).toList();
    final hasMore = _items.length > 5;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...preview.map((item) => _buildRow(item, currentUser)),
        if (hasMore || _items.length == 5)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpaceActivityScreen(
                    spaceId: widget.spaceId,
                    spaceName: widget.spaceName,
                  ),
                ),
              ),
              child: const Text(
                'View all contributions →',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(ActivityItem item, User? currentUser) {
    final isMe = currentUser != null && item.userId == currentUser.uid;
    final who = isMe ? 'You' : item.username;
    final action = item.type == 'photo' ? 'added a photo' : 'updated data';
    final timeStr = timeago.format(item.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: FaIcon(
              item.type == 'photo'
                  ? FontAwesomeIcons.camera
                  : FontAwesomeIcons.penToSquare,
              size: 12,
              color: AppColors.gray,
            ),
          ),
          Expanded(
            child: Text(
              '$who $action · $timeStr',
              style: const TextStyle(fontSize: 13, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}
