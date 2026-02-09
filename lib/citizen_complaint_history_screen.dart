import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenComplaintHistoryScreen extends StatefulWidget {
  const CitizenComplaintHistoryScreen({super.key});

  @override
  State<CitizenComplaintHistoryScreen> createState() =>
      _CitizenComplaintHistoryScreenState();
}

class _CitizenComplaintHistoryScreenState
    extends State<CitizenComplaintHistoryScreen> {

  String selectedStatus = "all";

  void openFilter() {
    String tempStatus = selectedStatus;

    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Filter",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField(
                value: tempStatus,
                items: const [
                  DropdownMenuItem(value: "all", child: Text("All")),
                  DropdownMenuItem(value: "pending", child: Text("Pending")),
                  DropdownMenuItem(value: "in progress", child: Text("In Progress")),
                  DropdownMenuItem(value: "resolved", child: Text("Resolved")),
                ],
                onChanged: (v) =>
                    setModalState(() => tempStatus = v.toString()),
                decoration: const InputDecoration(labelText: "Status"),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (!mounted) return;

                      setState(() {
                        selectedStatus = tempStatus;
                      });
                    });
                  },
                  child: const Text("Apply"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    Query q = FirebaseFirestore.instance
        .collection('complaints')
        .where('citizenEmail', isEqualTo: user?.email);

    if (selectedStatus != "all") {
      q = q.where('status', isEqualTo: selectedStatus);
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Complaints"),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: openFilter,
            ),
          ],
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: q.snapshots(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No complaints yet"));
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
                          d['issueType'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text("Status: ${d['status']}"),

                        const SizedBox(height: 6),

                        Text(
                          "Remark: ${d['panchayathRemark'] ?? 'No remark yet'}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
