import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'colors.dart';

class AdminPendingSubmissionsScreen extends StatefulWidget {
  const AdminPendingSubmissionsScreen({super.key});

  @override
  State<AdminPendingSubmissionsScreen> createState() =>
      _AdminPendingSubmissionsScreenState();
}

class _AdminPendingSubmissionsScreenState
    extends State<AdminPendingSubmissionsScreen> {
  String? _selectedDocId;
  Map<String, dynamic>? _selectedSubmission;

  static const Map<String, String> _typeLabels = {
    'park': 'Park',
    'pops': 'Privately Owned Public Space',
    'wpaa': 'Waterfront Public Access Area',
    'plaza': 'Street Plaza',
    'stp': 'Schoolyard to Playgrounds',
    'misc': 'Miscellaneous',
  };

  Future<void> _approve(String docId, Map<String, dynamic> data) async {
    try {
      final geometryStr = data['geometry'] as String? ?? '';

      final newSpaceData = {
        'name': data['name'] ?? '',
        'type': data['type'] ?? 'misc',
        'description': data['description'] ?? '',
        'geometry': geometryStr,
        'details': <String>[],
        'amenities': <String>[],
        'equipment': <String>[],
      };

      final batch = FirebaseFirestore.instance.batch();

      final newSpaceRef =
          FirebaseFirestore.instance.collection('public-spaces-main').doc();
      batch.set(newSpaceRef, newSpaceData);

      batch.update(
        FirebaseFirestore.instance
            .collection('public-spaces-submissions')
            .doc(docId),
        {'status': 'approved', 'approvedSpaceId': newSpaceRef.id},
      );

      await batch.commit();

      if (mounted) {
        setState(() {
          _selectedDocId = null;
          _selectedSubmission = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission approved and space added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reject(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('public-spaces-submissions')
          .doc(docId)
          .update({'status': 'rejected'});
      if (mounted) {
        setState(() {
          _selectedDocId = null;
          _selectedSubmission = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('New Space Submissions'),
        leading: _selectedDocId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedDocId = null;
                  _selectedSubmission = null;
                }),
              )
            : null,
      ),
      body: _selectedDocId != null && _selectedSubmission != null
          ? _buildDetailView(_selectedDocId!, _selectedSubmission!)
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('public-spaces-submissions')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No pending submissions.',
                style: TextStyle(color: AppColors.gray)),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? 'Unnamed';
            final type = data['type'] as String? ?? 'misc';
            final username = data['username'] as String? ?? 'unknown';
            final timestamp = data['timestamp'] as Timestamp?;
            final timeStr = timestamp != null
                ? timeago.format(timestamp.toDate())
                : '';

            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${_typeLabels[type] ?? type} · by $username · $timeStr'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() {
                  _selectedDocId = doc.id;
                  _selectedSubmission = data;
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailView(String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? '';
    final type = data['type'] as String? ?? 'misc';
    final description = data['description'] as String? ?? '';
    final username = data['username'] as String? ?? '';
    final geometry = data['geometry'] as String? ?? '';
    final timestamp = data['timestamp'] as Timestamp?;

    // Extract coords from geometry string for display
    String coordsDisplay = '';
    final coordMatch =
        RegExp(r'\[(-?\d+\.?\d*),(-?\d+\.?\d*)\]').firstMatch(geometry);
    if (coordMatch != null) {
      final lng = coordMatch.group(1);
      final lat = coordMatch.group(2);
      coordsDisplay = 'Lat: $lat, Lng: $lng';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_typeLabels[type] ?? type,
              style: const TextStyle(color: AppColors.gray)),
          if (timestamp != null)
            Text('Submitted by $username · ${timeago.format(timestamp.toDate())}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.gray)),
          const SizedBox(height: 20),
          if (description.isNotEmpty) ...[
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 16),
          ],
          if (coordsDisplay.isNotEmpty) ...[
            const Text('Location',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(coordsDisplay,
                style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(docId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approve(docId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve & Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
