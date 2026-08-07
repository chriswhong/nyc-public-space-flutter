import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../colors.dart';

// The 8 amenities tracked by the micro-survey system
const List<Map<String, dynamic>> _surveyAmenities = [
  {'key': 'restrooms', 'label': 'Restrooms', 'icon': FontAwesomeIcons.toilet},
  {'key': 'drinking_fountain', 'label': 'Water Fountain', 'icon': FontAwesomeIcons.water},
  {'key': 'seating', 'label': 'Seating', 'icon': FontAwesomeIcons.chair},
  {'key': 'tables', 'label': 'Tables', 'icon': FontAwesomeIcons.table},
  {'key': 'dog_park', 'label': 'Dog-Friendly', 'icon': FontAwesomeIcons.dog},
  {'key': 'accessible', 'label': 'Accessible', 'icon': FontAwesomeIcons.wheelchair},
];

class AmenitySurveySection extends StatefulWidget {
  final String spaceId;
  final Map<String, Map<String, int>> amenitySurvey;
  final Map<String, bool> userVotes;
  final VoidCallback onSignInRequired;

  const AmenitySurveySection({
    super.key,
    required this.spaceId,
    required this.amenitySurvey,
    required this.userVotes,
    required this.onSignInRequired,
  });

  @override
  State<AmenitySurveySection> createState() => _AmenitySurveySectionState();
}

class _AmenitySurveySectionState extends State<AmenitySurveySection> {
  late Map<String, bool?> _localVotes;
  late Map<String, Map<String, int>> _localCounts;
  final Set<String> _submitting = {};

  @override
  void initState() {
    super.initState();
    _initLocal();
  }

  void _initLocal() {
    _localVotes = {
      for (final a in _surveyAmenities)
        a['key'] as String: widget.userVotes[a['key'] as String]
    };
    _localCounts = {
      for (final a in _surveyAmenities)
        a['key'] as String: Map<String, int>.from(
            widget.amenitySurvey[a['key'] as String] ?? {'yes': 0, 'no': 0})
    };
  }

  @override
  void didUpdateWidget(covariant AmenitySurveySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) {
      _initLocal();
      _submitting.clear();
    } else if (_submitting.isEmpty &&
        (oldWidget.userVotes != widget.userVotes ||
            oldWidget.amenitySurvey != widget.amenitySurvey)) {
      _initLocal();
    }
  }

  Future<void> _castVote(String amenityKey, bool vote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      widget.onSignInRequired();
      return;
    }
    if (_submitting.contains(amenityKey)) return;

    final prevVote = _localVotes[amenityKey];
    final isToggleOff = prevVote == vote;
    final newVote = isToggleOff ? null : vote;

    // Optimistic update — votes and counts
    setState(() {
      _submitting.add(amenityKey);
      _localVotes[amenityKey] = newVote;
      final counts = _localCounts[amenityKey] ??= {'yes': 0, 'no': 0};
      if (prevVote != null) {
        final prevKey = prevVote ? 'yes' : 'no';
        counts[prevKey] = (counts[prevKey] ?? 1) - 1;
      }
      if (newVote != null) {
        final newKey = newVote ? 'yes' : 'no';
        counts[newKey] = (counts[newKey] ?? 0) + 1;
      }
    });

    try {
      final voteRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('amenity-votes')
          .doc(widget.spaceId);

      // Write user vote — no read required
      if (newVote != null) {
        await voteRef.set({amenityKey: newVote}, SetOptions(merge: true));
      } else {
        await voteRef.update({amenityKey: FieldValue.delete()});
      }

      // Best-effort aggregate update on the space doc
      final spaceUpdates = <String, dynamic>{};
      if (prevVote != null) {
        spaceUpdates['amenity_survey.$amenityKey.${prevVote ? 'yes' : 'no'}'] =
            FieldValue.increment(-1);
      }
      if (newVote != null) {
        spaceUpdates['amenity_survey.$amenityKey.${newVote ? 'yes' : 'no'}'] =
            FieldValue.increment(1);
      }
      if (spaceUpdates.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('public-spaces-main')
            .doc(widget.spaceId)
            .update(spaceUpdates)
            .catchError((_) {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localVotes[amenityKey] = prevVote;
          // Revert count changes
          final counts = _localCounts[amenityKey] ??= {'yes': 0, 'no': 0};
          if (newVote != null) {
            final newKey = newVote ? 'yes' : 'no';
            counts[newKey] = (counts[newKey] ?? 1) - 1;
          }
          if (prevVote != null) {
            final prevKey = prevVote ? 'yes' : 'no';
            counts[prevKey] = (counts[prevKey] ?? 0) + 1;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _submitting.remove(amenityKey));
    }
  }

  int _getCount(String key, String yesOrNo) {
    return _localCounts[key]?[yesOrNo] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Help others by answering what amenities this space has.',
          style: TextStyle(fontSize: 12, color: AppColors.gray),
        ),
        const SizedBox(height: 12),
        ..._surveyAmenities.map((amenity) {
          final key = amenity['key'] as String;
          final label = amenity['label'] as String;
          final icon = amenity['icon'] as FaIconData;
          final userVote = _localVotes[key];
          final isSubmitting = _submitting.contains(key);
          final yesCount = _getCount(key, 'yes');
          final noCount = _getCount(key, 'no');

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                FaIcon(icon, size: 14, color: AppColors.gray),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 13)),
                ),
                Opacity(
                  opacity: isSubmitting ? 0.5 : 1.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _VoteButton(
                        icon: Icons.thumb_up_outlined,
                        activeIcon: Icons.thumb_up,
                        count: yesCount,
                        isActive: userVote == true,
                        onTap: isSubmitting ? () {} : () => _castVote(key, true),
                      ),
                      const SizedBox(width: 6),
                      _VoteButton(
                        icon: Icons.thumb_down_outlined,
                        activeIcon: Icons.thumb_down,
                        count: noCount,
                        isActive: userVote == false,
                        onTap: isSubmitting ? () {} : () => _castVote(key, false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.dark : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.dark : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 13,
              color: isActive ? Colors.white : AppColors.gray,
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.white : AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
