import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanchayathIllegalDumpingScreen extends StatelessWidget {
  const PanchayathIllegalDumpingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Illegal Dumping Reports"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('illegal_dumping_reports') // ✅ FIXED — SAME AS CITIZEN
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No illegal dumping reports"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text("Location: ${data['location']}"),

                      const SizedBox(height: 6),

                      Text("Citizen: ${data['citizenEmail']}"),

                      if (data['proofUrl'] != null)
                        Text(
                          data['proofUrl'],
                          style: const TextStyle(color: Colors.blue),
                        ),

                      const SizedBox(height: 6),

                      Text("Status: ${data['status']}"),
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
