import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'colors.dart';
import 'geojson_provider.dart';
import 'public_space_properties.dart';

class ActivityItem {
  final String id;
  final String type; // 'photo' or 'edit'
  final String spaceId;
  final String userId;
  final String username;
  final DateTime timestamp;

  ActivityItem({
    required this.id,
    required this.type,
    required this.spaceId,
    required this.userId,
    required this.username,
    required this.timestamp,
  });
}

class ActivityFeedScreen extends StatefulWidget {
  final Function(String spaceId) onSpaceSelected;

  const ActivityFeedScreen({super.key, required this.onSpaceSelected});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  List<ActivityItem> _allItems = [];
  List<ActivityItem> _myItems = [];
  bool _loading = true;
  String? _error;

  StreamSubscription<QuerySnapshot>? _imagesSubscription;
  StreamSubscription<QuerySnapshot>? _editsSubscription;
  List<ActivityItem> _imageItems = [];
  List<ActivityItem> _editItems = [];

  @override
  void initState() {
    super.initState();
    _subscribeToFeeds();
  }

  @override
  void dispose() {
    _imagesSubscription?.cancel();
    _editsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToFeeds() {
    final db = FirebaseFirestore.instance;

    _imagesSubscription = db
        .collection('images')
        .where('status', isEqualTo: 'approved')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        _imageItems = snapshot.docs.map((doc) {
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
        _rebuildList();
      },
      onError: (e) {
        // ignore: avoid_print
        print('ActivityFeed images error: $e');
        setState(() => _error = e.toString());
      },
    );

    _editsSubscription = db
        .collection('public-spaces-edits')
        .where('status', isEqualTo: 'approved')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        _editItems = snapshot.docs.map((doc) {
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
        _rebuildList();
      },
      onError: (e) {
        // ignore: avoid_print
        print('ActivityFeed edits error: $e');
        setState(() => _error = e.toString());
      },
    );
  }

  void _rebuildList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final merged = [..._imageItems, ..._editItems];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _allItems = merged;
      _myItems = currentUser != null
          ? merged.where((item) => item.userId == currentUser.uid).toList()
          : [];
      _loading = false;
    });
  }

  PublicSpaceFeature? _getFeature(
      String spaceId, List<PublicSpaceFeature> features) {
    try {
      return features.firstWhere((f) => f.properties.firestoreId == spaceId);
    } catch (_) {
      return null;
    }
  }

  String? _boroughFromFeature(PublicSpaceFeature feature) {
    final lat = feature.geometry.coordinates.lat.toDouble();
    final lng = feature.geometry.coordinates.lng.toDouble();
    // Staten Island first — isolated enough that simple bounds work reliably
    if (lat >= 40.4774 && lat <= 40.6501 && lng >= -74.2591 && lng <= -74.0341) {
      return 'Staten Island';
    }
    if (lat >= 40.6999 && lat <= 40.8816 && lng >= -74.0479 && lng <= -73.9067) {
      return 'Manhattan';
    }
    if (lat >= 40.7855 && lat <= 40.9176 && lng >= -73.9339 && lng <= -73.7654) {
      return 'Bronx';
    }
    if (lat >= 40.5707 && lat <= 40.7395 && lng >= -74.0421 && lng <= -73.8333) {
      return 'Brooklyn';
    }
    if (lat >= 40.5431 && lat <= 40.8007 && lng >= -73.9625 && lng <= -73.7004) {
      return 'Queens';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Activity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: AppColors.dark,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: AppColors.green,
            tabs: [
              Tab(text: 'All Activity'),
              Tab(text: 'My Activity'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllActivityTab(),
            _buildMyActivityTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllActivityTab() {
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
    if (_allItems.isEmpty) {
      return const Center(child: Text('No activity yet.'));
    }
    return _buildList(_allItems);
  }

  Widget _buildMyActivityTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return _buildSignInPrompt();
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myItems.isEmpty) {
      return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'None of your contributions have been approved yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.gray),
        ),
      ),
    );
    }
    return _buildList(_myItems);
  }

  Widget _buildSignInPrompt() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.user, size: 48, color: AppColors.gray),
            SizedBox(height: 16),
            Text(
              'Sign in to see your activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Track your approved photos and data edits after signing in.',
              style: TextStyle(color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ActivityItem> items) {
    final features =
        Provider.of<GeoJsonProvider>(context, listen: true).features;
    final currentUser = FirebaseAuth.instance.currentUser;

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final item = items[index];
        final feature = _getFeature(item.spaceId, features);
        final spaceName = feature?.properties.name ?? 'Unknown Space';
        final borough = feature != null ? _boroughFromFeature(feature) : null;
        final isCurrentUser =
            currentUser != null && item.userId == currentUser.uid;
        final who = isCurrentUser ? 'You' : item.username;
        final action = item.type == 'photo' ? 'added a photo to' : 'updated data for';
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
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FaIcon(FontAwesomeIcons.user,
                        size: 11, color: AppColors.gray),
                  ),
                ),
                TextSpan(
                  text: who,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' $action '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FaIcon(FontAwesomeIcons.locationDot,
                        size: 11, color: AppColors.gray),
                  ),
                ),
                TextSpan(
                  text: spaceName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          subtitle: Text(
            borough != null ? '$timeStr · $borough' : timeStr,
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
          onTap: () => widget.onSpaceSelected(item.spaceId),
        );
      },
    );
  }
}
