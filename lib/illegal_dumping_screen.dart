import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IllegalDumpingScreen extends StatefulWidget {
  const IllegalDumpingScreen({super.key});

  @override
  State<IllegalDumpingScreen> createState() => _IllegalDumpingScreenState();
}

class _IllegalDumpingScreenState extends State<IllegalDumpingScreen> {

  String selectedStatus = "all";
  DateTime? selectedDate;

  final descController = TextEditingController();
  final locationController = TextEditingController();
  final photoController = TextEditingController(); // ✅ NEW

  bool submitting = false;

  // ---------------- FILTER SHEET ----------------

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text("Filters",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              DropdownButtonFormField(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: "all", child: Text("All")),
                  DropdownMenuItem(value: "pending", child: Text("Pending")),
                  DropdownMenuItem(value: "in progress", child: Text("In Progress")),
                  DropdownMenuItem(value: "resolved", child: Text("Resolved")),
                ],
                onChanged: (v) => setState(() => selectedStatus = v.toString()),
                decoration: const InputDecoration(labelText: "Status"),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );

                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Text(
                  selectedDate == null
                      ? "Select Date"
                      : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Apply Filters"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- SUBMIT REPORT ----------------

  Future<void> submitReport() async {
    if (descController.text.isEmpty ||
        locationController.text.isEmpty ||
        photoController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => submitting = true);

    await FirebaseFirestore.instance.collection('illegal_dumping_reports').add({
      "description": descController.text.trim(),
      "location": locationController.text.trim(),
      "photoUrl": photoController.text.trim(), // ✅ SAVED
      "status": "pending",
      "createdAt": Timestamp.now(),
    });

    descController.clear();
    locationController.clear();
    photoController.clear();

    setState(() => submitting = false);

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

            const SizedBox(height: 10),

            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: photoController,
              decoration: const InputDecoration(labelText: "Photo URL"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),

          ElevatedButton(
            onPressed: submitting ? null : submitReport,
            child: const Text("Submit"),
          )
        ],
      ),
    );
  }

  // ---------------- MAIN UI ----------------

  @override
  Widget build(BuildContext context) {

    Query query =
    FirebaseFirestore.instance.collection('illegal_dumping_reports');

    if (selectedStatus != "all") {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    if (selectedDate != null) {
      final start = Timestamp.fromDate(
        DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day),
      );
      final end = Timestamp.fromDate(
        DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day + 1),
      );

      query = query
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end);
    }

    query = query.orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Illegal Dumping Reports"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        onPressed: openSubmitDialog,
        icon: const Icon(Icons.add),
        label: const Text("Report"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
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

                      Text(d['description'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),

                      const SizedBox(height: 6),

                      Text("Location: ${d['location']}"),
                      Text("Status: ${d['status']}"),

                      const SizedBox(height: 6),

                      if (d['photoUrl'] != null)
                        Text("Photo: ${d['photoUrl']}"),
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
