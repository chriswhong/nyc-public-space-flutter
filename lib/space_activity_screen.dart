import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'activity_feed_screen.dart';
import 'colors.dart';

class SpaceActivityScreen extends StatefulWidget {
  final String spaceId;
  final String spaceName;

  const SpaceActivityScreen({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  State<SpaceActivityScreen> createState() => _SpaceActivityScreenState();
}

class _SpaceActivityScreenState extends State<SpaceActivityScreen> {
  List<ActivityItem> _items = [];
  bool _loading = true;
  String? _error;

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
        .listen(
      (snap) {
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
      },
      onError: (e) => setState(() => _error = e.toString()),
    );

    _editsSub = db
        .collection('public-spaces-edits')
        .where('spaceId', isEqualTo: widget.spaceId)
        .where('status', isEqualTo: 'approved')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snap) {
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
      },
      onError: (e) => setState(() => _error = e.toString()),
    );
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contributions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              widget.spaceName,
              style: const TextStyle(fontSize: 12, color: AppColors.gray),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error loading activity: $_error',
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No approved contributions yet.',
            style: TextStyle(color: AppColors.gray),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final item = _items[index];
        final isMe = currentUser != null && item.userId == currentUser.uid;
        final who = isMe ? 'You' : item.username;
        final action = item.type == 'photo'
            ? 'added a photo'
            : 'updated space data';
        final timeStr = timeago.format(item.timestamp);

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: item.type == 'photo'
                ? AppColors.green.withValues(alpha: 0.15)
                : AppColors.dark.withValues(alpha: 0.08),
            child: FaIcon(
              item.type == 'photo'
                  ? FontAwesomeIcons.camera
                  : FontAwesomeIcons.penToSquare,
              color: item.type == 'photo' ? AppColors.green : AppColors.dark,
              size: 16,
            ),
          ),
          title: Text('$who $action',
              style: const TextStyle(fontSize: 14)),
          subtitle: Text(timeStr,
              style: const TextStyle(color: AppColors.gray, fontSize: 12)),
        );
      },
    );
  }
}
