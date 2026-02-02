import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {

  final descriptionController = TextEditingController();
  final photoUrlController = TextEditingController();
  final locationController = TextEditingController();

  String? issueType;
  bool loading = false;

  final issues = [
    "Missed Collection",
    "Overflowing Bin",
    "Illegal Dumping",
    "Burning Waste",
    "Blocked Drain",
    "Other",
  ];

  Future<void> submit() async {

    if (issueType == null ||
        descriptionController.text.isEmpty ||
        locationController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection("hks_complaints").add({
      "hksEmail": user?.email,
      "issueType": issueType,
      "location": locationController.text.trim(),
      "description": descriptionController.text.trim(),
      "photoUrl": photoUrlController.text.trim(),
      "createdAt": Timestamp.now(),
      "status": "pending",
    });

    setState(() => loading = false);

    Navigator.pop(context);
  }

  InputDecoration input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F3),
      appBar: AppBar(
        title: const Text("New Complaint"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Issue Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            DropdownButtonFormField(
              value: issueType,
              decoration: input("Select issue"),
              items: issues.map((e) =>
                  DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => issueType = v.toString()),
            ),

            const SizedBox(height: 16),

            const Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            TextField(
              controller: locationController,
              decoration: input("Area / Ward / Street"),
            ),

            const SizedBox(height: 16),

            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: input("Describe the issue..."),
            ),

            const SizedBox(height: 16),

            const Text(
              "Photo URL (optional)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            TextField(
              controller: photoUrlController,
              decoration: input("Paste image link"),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "SUBMIT",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
