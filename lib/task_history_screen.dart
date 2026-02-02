import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskHistoryScreen extends StatelessWidget {
  final String workerId;

  const TaskHistoryScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task History"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('worker_tasks')
            .where('workerId', isEqualTo: workerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;

          if (tasks.isEmpty) {
            return const Center(child: Text("No history"));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (_, i) {

              final t = tasks[i];

              final date = (t['createdAt'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(t['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${t['status']}"),
                      Text("${date.day}-${date.month}-${date.year}")
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
