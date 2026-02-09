import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IllegalDumpingScreen extends StatefulWidget {
  const IllegalDumpingScreen({super.key});

  @override
  State<IllegalDumpingScreen> createState() => _IllegalDumpingScreenState();
}

class _IllegalDumpingScreenState extends State<IllegalDumpingScreen> {

  final descController = TextEditingController();
  final locationController = TextEditingController();
  final photoController = TextEditingController();

  bool submitting = false;

  // ---------- SUBMIT REPORT ----------

  Future<void> submitReport() async {
    if (descController.text.isEmpty ||
        locationController.text.isEmpty ||
        photoController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('illegal_dumping_reports').add({
      "description": descController.text.trim(),
      "location": locationController.text.trim(),
      "photoUrl": photoController.text.trim(),
      "status": "pending",
      "createdAt": Timestamp.now(),
      "citizenEmail": user?.email, // IMPORTANT
    });

    descController.clear();
    locationController.clear();
    photoController.clear();

    Navigator.pop(context);
  }

  void openSubmitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Report Illegal Dumping"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),

            TextField(
              controller: photoController,
              decoration: const InputDecoration(labelText: "Photo URL"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: submitReport, child: const Text("Submit"))
        ],
      ),
    );
  }

  // ---------- MAIN UI ----------

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    Query query = FirebaseFirestore.instance
        .collection('illegal_dumping_reports')
        .where('citizenEmail', isEqualTo: user?.email)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Illegal Dumping Reports"),
        backgroundColor: Colors.green,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: openSubmitDialog,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports yet"));
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
                      Text(d['description'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Location: ${d['location']}"),
                      Text("Status: ${d['status']}"),
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
