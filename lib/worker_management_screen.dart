import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_worker_screen.dart';
import 'worker_dashboard_screen.dart';
import 'view_workers_screen.dart';

class WorkerManagementScreen extends StatelessWidget {
  const WorkerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workforce Management"),
        backgroundColor: Colors.green,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.person_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWorkerScreen()),
          );
        },
      ),

      body: Column(
        children: [

          // ✅ VIEW WORKERS / ASSIGN ROUTES BUTTON
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                icon: const Icon(Icons.assignment),
                label: const Text("View Workers / Assign Routes"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewWorkersScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('workers').snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final workers = snapshot.data!.docs;

                if (workers.isEmpty) {
                  return const Center(child: Text("No workers found"));
                }

                return ListView.builder(
                  itemCount: workers.length,
                  itemBuilder: (context, index) {

                    final doc = workers[index];
                    final d = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final name = d['name'] ?? '';
                    final email = d['email'] ?? '';
                    final active = d['active'] ?? true;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(email),

                        trailing: Switch(
                          value: active,
                          onChanged: (v) {
                            FirebaseFirestore.instance
                                .collection('workers')
                                .doc(docId)
                                .update({'active': v});
                          },
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerDashboardScreen(
                                workerEmail: email,
                              ),
                            ),
                          );
                        },
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
