import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanchayathIllegalDumpingScreen extends StatelessWidget {
  const PanchayathIllegalDumpingScreen({super.key});

  Future<void> updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('illegal_dumping_reports')
        .doc(docId)
        .update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Illegal Dumping Reports"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('illegal_dumping_reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        d['description'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),

                      const SizedBox(height: 6),

                      Text("Location: ${d['location']}"),
                      Text("Citizen: ${d['citizenEmail']}"),
                      Text("Status: ${d['status']}"),

                      const SizedBox(height: 10),

                      Row(
                        children: [

                          ElevatedButton(
                            onPressed: () =>
                                updateStatus(doc.id, "in progress"),
                            child: const Text("Progress"),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            onPressed: () =>
                                updateStatus(doc.id, "resolved"),
                            child: const Text("Resolved"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
