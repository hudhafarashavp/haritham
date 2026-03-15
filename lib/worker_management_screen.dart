import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_worker_screen.dart';
import 'worker_dashboard_screen.dart';
import 'view_workers_screen.dart';
import 'widgets/app_theme.dart';
import 'widgets/custom_widgets.dart';

class WorkerManagementScreen extends StatelessWidget {
  const WorkerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Workforce Management"), elevation: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.harithamGreen,
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWorkerScreen()),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.padding),
            child: HarithamButton(
              label: "View Workers / Assign Routes",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewWorkersScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('workers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final workers = snapshot.data!.docs;

                if (workers.isEmpty) {
                  return const Center(child: Text("No workers found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.padding,
                  ),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final doc = workers[index];
                    final d = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final name = d['name'] ?? '';
                    final email = d['email'] ?? '';
                    final active = d['active'] ?? true;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HarithamCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkerDashboardScreen(workerEmail: email),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(email),
                          trailing: Switch(
                            activeColor: AppTheme.harithamGreen,
                            value: active,
                            onChanged: (v) {
                              FirebaseFirestore.instance
                                  .collection('workers')
                                  .doc(docId)
                                  .update({'active': v});
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
