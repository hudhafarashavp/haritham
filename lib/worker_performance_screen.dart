import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerPerformanceScreen extends StatelessWidget {
  final String workerEmail;

  const WorkerPerformanceScreen({
    super.key,
    required this.workerEmail,
  });

  @override
  Widget build(BuildContext context) {
    final tasksRef = FirebaseFirestore.instance
        .collection('worker_tasks')
        .where('workerEmail', isEqualTo: workerEmail);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Performance"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksRef.snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTasks = snapshot.data!.docs;

          final completed =
              allTasks.where((e) => e['status'] == 'completed').length;

          final assigned =
              allTasks.where((e) => e['status'] == 'assigned').length;

          return Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat("Assigned", assigned),
                    _stat("Completed", completed),
                  ],
                ),
              ),

              const Divider(),

              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "Task History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: allTasks.length,
                  itemBuilder: (context, i) {
                    final t = allTasks[i];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(t['taskTitle']),
                        subtitle: Text(t['status']),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text(value.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}
