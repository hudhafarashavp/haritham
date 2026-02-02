import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_notification_screen.dart';

class PanchayathNotificationManagementScreen extends StatelessWidget {
  const PanchayathNotificationManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Manage Notifications'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final viewedBy = (data['viewedBy'] ?? {}) as Map<String, dynamic>;

              // ✅ ONLY HKS MAP
              final hksSeenMap =
              (viewedBy['hks'] is Map<String, dynamic>)
                  ? (viewedBy['hks'] as Map<String, dynamic>)
                  : <String, dynamic>{};

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(data['message'] ?? ''),
                      const SizedBox(height: 8),

                      Text(
                        'Target: ${data['target']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'HKS View Status (Individual):',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      if (hksSeenMap.isEmpty)
                        const Text(
                          'No HKS viewed yet',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: hksSeenMap.entries.map((entry) {
                            final workerId = entry.key;
                            final seen = entry.value == true;
                            return Chip(
                              label: Text(
                                seen
                                    ? '$workerId: Seen'
                                    : '$workerId: Not Seen',
                              ),
                              backgroundColor: seen
                                  ? Colors.green[100]
                                  : Colors.red[100],
                            );
                          }).toList(),
                        ),

                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateNotificationScreen(
                                    docId: doc.id,
                                    oldTitle: data['title'],
                                    oldMessage: data['message'],
                                    oldTarget: data['target'],
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteNotification(context, doc.id);
                            },
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
      ),
    );
  }

  static Future<void> _deleteNotification(
      BuildContext context,
      String docId,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();
    }
  }
}
