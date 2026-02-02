import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanchayathAllComplaintsScreen extends StatelessWidget {
  const PanchayathAllComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Complaints"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('') // dummy
            .snapshots(),
        builder: (context, snapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .snapshots(),
            builder: (context, citizenSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('hks_complaints')
                    .snapshots(),
                builder: (context, hksSnap) {

                  if (!citizenSnap.hasData || !hksSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDocs = [
                    ...citizenSnap.data!.docs,
                    ...hksSnap.data!.docs,
                  ];

                  if (allDocs.isEmpty) {
                    return const Center(child: Text("No complaints"));
                  }

                  return ListView.builder(
                    itemCount: allDocs.length,
                    itemBuilder: (context, index) {
                      final data = allDocs[index].data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['issueType'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(data['description'] ?? ''),
                              const SizedBox(height: 6),
                              Text("Status: ${data['status']}"),
                            ],
                          ),
                        ),
                      );
                    },
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
