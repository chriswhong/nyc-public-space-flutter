import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'colors.dart';

class AdminPendingImagesScreen extends StatelessWidget {
  const AdminPendingImagesScreen({super.key});

  Future<String> _getThumbnailUrl(String spaceId, String filename) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('spaces_images/$spaceId/thumbnail/$filename');
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('images')
        .doc(docId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('images')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No pending images',
              style: TextStyle(color: AppColors.gray, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            final spaceId = data['spaceId'] as String? ?? '';
            final filename = data['filename'] as String? ?? '';
            final username = data['username'] as String? ?? 'Unknown';
            final timestamp = data['timestamp'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space info
                    _SpaceNameLoader(spaceId: spaceId),
                    const SizedBox(height: 4),
                    Text(
                      'by $username${timestamp != null ? ' · ${_formatTimestamp(timestamp)}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Thumbnail
                    FutureBuilder<String>(
                      future: _getThumbnailUrl(spaceId, filename),
                      builder: (context, urlSnap) {
                        if (!urlSnap.hasData || urlSnap.data!.isEmpty) {
                          return Container(
                            height: 200,
                            color: AppColors.pageBackground,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            urlSnap.data!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(docId, 'rejected'),
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
                            onPressed: () => _updateStatus(docId, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class _SpaceNameLoader extends StatelessWidget {
  final String spaceId;

  const _SpaceNameLoader({required this.spaceId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('public-spaces-main')
          .doc(spaceId)
          .get(),
      builder: (context, snap) {
        String name = 'Loading...';
        if (snap.hasData && snap.data!.exists) {
          name = (snap.data!.data() as Map<String, dynamic>)['name'] as String? ?? spaceId;
        } else if (snap.hasError || snap.connectionState == ConnectionState.done) {
          name = spaceId;
        }
        return Text(
          name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        );
      },
    );
  }
}
