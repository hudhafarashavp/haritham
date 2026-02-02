import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanchayathDashboardScreen extends StatelessWidget {
  const PanchayathDashboardScreen({super.key});

  Widget statBox(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint Dashboard"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          int pending = 0;
          int progress = 0;
          int resolved = 0;

          for (var d in docs) {
            final status = (d['status'] ?? 'pending').toString();

            if (status == "pending") pending++;
            if (status == "in progress") progress++;   // ✅ FIXED HERE
            if (status == "resolved") resolved++;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Row(
                  children: [
                    statBox("Pending", pending, Colors.orange),
                    statBox("In Progress", progress, Colors.blue),
                    statBox("Resolved", resolved, Colors.green),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  "Total Complaints: ${docs.length}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
