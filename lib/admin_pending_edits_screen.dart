import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'colors.dart';

class AdminPendingEditsScreen extends StatefulWidget {
  const AdminPendingEditsScreen({super.key});

  @override
  State<AdminPendingEditsScreen> createState() => _AdminPendingEditsScreenState();
}

class _AdminPendingEditsScreenState extends State<AdminPendingEditsScreen> {
  String? _selectedDocId;
  Map<String, dynamic>? _selectedEdit;
  Map<String, dynamic>? _currentSpaceData;
  bool _loadingDetail = false;

  Future<void> _loadDetail(String docId, Map<String, dynamic> editData) async {
    setState(() {
      _selectedDocId = docId;
      _selectedEdit = editData;
      _loadingDetail = true;
      _currentSpaceData = null;
    });

    final spaceId = editData['spaceId'] as String?;
    if (spaceId != null) {
      final snap = await FirebaseFirestore.instance
          .collection('public-spaces-main')
          .doc(spaceId)
          .get();
      if (mounted && snap.exists) {
        setState(() {
          _currentSpaceData = snap.data();
        });
      }
    }

    if (mounted) setState(() => _loadingDetail = false);
  }

  Future<void> _approve() async {
    if (_selectedEdit == null || _currentSpaceData == null) return;

    final spaceId = _selectedEdit!['spaceId'] as String?;
    if (spaceId == null) return;

    final proposedData = _selectedEdit!['proposedData'] as Map<String, dynamic>? ?? {};
    final updatedData = {..._currentSpaceData!, ...proposedData};

    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      FirebaseFirestore.instance.collection('public-spaces-main').doc(spaceId),
      updatedData,
      SetOptions(merge: true),
    );
    batch.update(
      FirebaseFirestore.instance.collection('public-spaces-edits').doc(_selectedDocId),
      {'status': 'approved'},
    );
    await batch.commit();

    if (mounted) {
      setState(() {
        _selectedDocId = null;
        _selectedEdit = null;
        _currentSpaceData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit approved')),
      );
    }
  }

  Future<void> _reject() async {
    if (_selectedDocId == null) return;

    await FirebaseFirestore.instance
        .collection('public-spaces-edits')
        .doc(_selectedDocId)
        .update({'status': 'rejected'});

    if (mounted) {
      setState(() {
        _selectedDocId = null;
        _selectedEdit = null;
        _currentSpaceData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit rejected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('public-spaces-edits')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading edits'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No pending edits',
              style: TextStyle(color: AppColors.gray, fontSize: 16),
            ),
          );
        }

        // If we have a selected edit open, show the detail view
        if (_selectedDocId != null && _selectedEdit != null) {
          return _buildDetailView(docs);
        }

        return _buildList(docs);
      },
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final userName = data['userName'] as String? ?? 'Unknown';
        final timestamp = data['timestamp'] as Timestamp?;
        final proposedData = data['proposedData'] as Map<String, dynamic>? ?? {};
        final fieldCount = proposedData.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: _SpaceNameText(spaceId: data['spaceId'] as String? ?? ''),
            subtitle: Text(
              '$fieldCount field${fieldCount == 1 ? '' : 's'} changed · by $userName'
              '${timestamp != null ? ' · ${_formatTimestamp(timestamp)}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.gray),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.gray),
            onTap: () => _loadDetail(doc.id, data),
          ),
        );
      },
    );
  }

  Widget _buildDetailView(List<QueryDocumentSnapshot> docs) {
    final proposedData = _selectedEdit!['proposedData'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Back button row
        Container(
          color: Colors.white,
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedDocId = null;
                  _selectedEdit = null;
                  _currentSpaceData = null;
                }),
                icon: const Icon(Icons.arrow_back, color: AppColors.dark),
                label: const Text('All Edits', style: TextStyle(color: AppColors.dark)),
              ),
            ],
          ),
        ),
        // Space name header
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SpaceNameText(
                spaceId: _selectedEdit!['spaceId'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'by ${_selectedEdit!['userName'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Diff content
        Expanded(
          child: _loadingDetail
              ? const Center(child: CircularProgressIndicator())
              : _buildDiff(proposedData),
        ),
        // Action buttons
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentSpaceData != null ? _approve : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiff(Map<String, dynamic> proposedData) {
    if (_currentSpaceData == null) {
      return const Center(
        child: Text('Could not load current data', style: TextStyle(color: AppColors.gray)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: proposedData.entries.map((entry) {
        final field = entry.key;
        final newValue = entry.value;
        final oldValue = _currentSpaceData![field];
        final hasChanged = oldValue?.toString() != newValue?.toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasChanged && oldValue != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatValue(oldValue),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB71C1C),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatValue(newValue),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '(empty)';
    if (value is List) return value.join(', ');
    return value.toString();
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

class _SpaceNameText extends StatelessWidget {
  final String spaceId;
  final TextStyle? style;

  const _SpaceNameText({required this.spaceId, this.style});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('public-spaces-main')
          .doc(spaceId)
          .get(),
      builder: (context, snap) {
        String name = spaceId;
        if (snap.hasData && snap.data!.exists) {
          name = (snap.data!.data() as Map<String, dynamic>)['name'] as String? ?? spaceId;
        }
        return Text(
          name,
          style: style ??
              const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
        );
      },
    );
  }
}
