import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerDashboardScreen extends StatelessWidget {
  final String workerEmail;

  const WorkerDashboardScreen({
    super.key,
    required this.workerEmail,
  });

  @override
  Widget build(BuildContext context) {

    final today =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Dashboard"),
        backgroundColor: Colors.green,
      ),

      body: Column(
        children: [

          // ================= TODAY ROUTE =================
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('worker_schedules')
                .where('workerEmail', isEqualTo: workerEmail)
                .where('date', isEqualTo: today)
                .snapshots(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("No schedule today"),
                );
              }

              final d = snapshot.data!.docs.first.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text("TODAY",
                          style: TextStyle(fontWeight: FontWeight.bold)),

                      Text("Route: ${d['routeName']}"),
                      Text("Time: ${d['startTime']} - ${d['endTime']}"),
                      Text("Status: ${d['status']}"),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // ================= PERFORMANCE =================
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('worker_schedules')
                .where('workerEmail', isEqualTo: workerEmail)
                .snapshots(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) return SizedBox();

              final all = snapshot.data!.docs;
              final completed =
                  all.where((e) => e['status'] == 'completed').length;

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Performance: $completed / ${all.length} tasks completed",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),

          const Divider(),

          // ================= HISTORY =================
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "Task History",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('worker_schedules')
                  .where('workerEmail', isEqualTo: workerEmail)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {

                    final d = tasks[i].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(d['routeName']),
                      subtitle: Text("${d['date']} | ${d['status']}"),
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
