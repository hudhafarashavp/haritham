import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_notification_screen.dart';

class HksNotificationManagementScreen extends StatelessWidget {
  const HksNotificationManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Manage My Notifications'),
        backgroundColor: const Color(0xFFE8F5E9),
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('createdBy', isEqualTo: 'hks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, notificationSnapshot) {
          if (notificationSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationSnapshot.hasError) {
            // ✅ shows error instead of infinite loading
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${notificationSnapshot.error}\n\n'
                      'If you see FAILED_PRECONDITION, create Firestore composite index:\n'
                      'createdBy Ascending + createdAt Descending',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!notificationSnapshot.hasData ||
              notificationSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          final notifications = notificationSnapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              final Map<String, dynamic> viewedBy =
              Map<String, dynamic>.from(data['viewedBy'] ?? {});

              // ✅ Worker wise HKS viewed status
              final Map<String, dynamic> hksSeenMap =
              (viewedBy['hks'] is Map<String, dynamic>)
                  ? Map<String, dynamic>.from(viewedBy['hks'])
                  : {};

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

                      const SizedBox(height: 10),

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
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(doc.id)
                                  .delete();
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
}
