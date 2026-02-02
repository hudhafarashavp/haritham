import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerTasksScreen extends StatelessWidget {
  final String workerId;

  const WorkerTasksScreen({super.key, required this.workerId});

  Future<void> completeTask(String taskId) async {
    await FirebaseFirestore.instance
        .collection('worker_tasks')
        .doc(taskId)
        .update({'status': 'completed'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Tasks")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('worker_tasks')
            .where('workerId', isEqualTo: workerId)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tasks = snapshot.data!.docs;

          if (tasks.isEmpty) return const Center(child: Text("No tasks"));

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (_, i) {

              final t = tasks[i];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(t['title']),
                  subtitle: Text("Status: ${t['status']}"),

                  trailing: t['status'] == 'assigned'
                      ? ElevatedButton(
                    child: const Text("Complete"),
                    onPressed: () => completeTask(t.id),
                  )
                      : const Text("Done"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
