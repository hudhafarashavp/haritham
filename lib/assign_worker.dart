import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignWorkerScreen extends StatelessWidget {
  final String complaintId;

  const AssignWorkerScreen({super.key, required this.complaintId});

  Future<void> assignWorker(String workerId) async {
    await FirebaseFirestore.instance
        .collection('worker_tasks')
        .doc(complaintId)
        .set({
      'workerId': workerId,
      'title': 'Complaint Cleanup',
      'status': 'assigned',
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Worker")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('workers').snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final workers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (_, i) {
              final w = workers[i];

              return ListTile(
                title: Text(w['name']),
                trailing: ElevatedButton(
                  child: const Text("Assign"),
                  onPressed: () async {
                    await assignWorker(w.id);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
