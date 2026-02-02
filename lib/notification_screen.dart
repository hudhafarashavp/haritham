import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'create_notification_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Future<void> _markSeen({
    required String docId,
    required String role,
    required String hksId,
  }) async {
    // ✅ ONLY track HKS worker wise
    if (role != 'hks') return;

    await FirebaseFirestore.instance.collection('notifications').doc(docId).set(
      {
        'viewedBy': {
          'hks': {
            hksId: true,
          }
        }
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFE8F5E9),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, prefsSnap) {
          if (!prefsSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = prefsSnap.data!;
          final role = prefs.getString('role') ?? '';

          // ✅ HKS worker id (must be stored during login)
          final hksId = prefs.getString('hksId') ??
              prefs.getString('userId') ??
              'unknown_hks';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final target = data['target'];
                return target == 'all' || target == role;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('No notifications'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final title = data['title'] ?? '';
                  final message = data['message'] ?? '';

                  final Map<String, dynamic> viewedBy =
                  Map<String, dynamic>.from(data['viewedBy'] ?? {});

                  // ✅ Worker wise seen check
                  final Map<String, dynamic> hksSeenMap =
                  (viewedBy['hks'] is Map<String, dynamic>)
                      ? Map<String, dynamic>.from(viewedBy['hks'])
                      : {};

                  final bool thisHksSeen = hksSeenMap[hksId] == true;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      onTap: () async {
                        await _markSeen(
                          docId: doc.id,
                          role: role,
                          hksId: hksId,
                        );
                      },

                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // ✅ Only HKS itself can see its own seen status icon
                          if (role == 'hks')
                            Icon(
                              thisHksSeen
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 18,
                              color: thisHksSeen ? Colors.green : Colors.grey,
                            ),
                        ],
                      ),
                      subtitle: Text(message),

                      trailing: role == 'panchayath'
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateNotificationScreen(
                                    docId: doc.id,
                                    oldTitle: title,
                                    oldMessage: message,
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
                      )
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
