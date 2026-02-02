import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'complaint_history_screen.dart';

class PanchayathComplaintsScreen extends StatefulWidget {
  const PanchayathComplaintsScreen({super.key});

  @override
  State<PanchayathComplaintsScreen> createState() =>
      _PanchayathComplaintsScreenState();
}

class _PanchayathComplaintsScreenState
    extends State<PanchayathComplaintsScreen> {

  String selectedStatus = "all";
  String selectedType = "all";
  DateTime? selectedDate;

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      "status": status,
      "statusHistory": FieldValue.arrayUnion([
        {"status": status, "time": Timestamp.now()}
      ])
    });
  }

  Future<void> _assign(String docId) async {
    String worker = "hks1@gmail.com";

    await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      "assignedWorker": worker,
      "scheduledDate": Timestamp.now(),
      "status": "in_progress",
    });

    await FirebaseFirestore.instance.collection('worker_tasks').add({
      'workerEmail': worker,
      'taskTitle': 'Complaint Cleanup',
      'status': 'assigned',
      'date': Timestamp.now(),
    });
  }

  void openFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text("Filters",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            DropdownButtonFormField(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: "all", child: Text("All Status")),
                DropdownMenuItem(value: "pending", child: Text("Pending")),
                DropdownMenuItem(value: "in progress", child: Text("In Progress")),
                DropdownMenuItem(value: "resolved", child: Text("Resolved")),
              ],
              onChanged: (v) => setState(() => selectedStatus = v.toString()),
              decoration: const InputDecoration(labelText: "Status"),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "all", child: Text("All Types")),
                DropdownMenuItem(value: "Burning waste", child: Text("Burning waste")),
                DropdownMenuItem(value: "Garbage overflow", child: Text("Garbage overflow")),
                DropdownMenuItem(value: "Illegal dumping", child: Text("Illegal dumping")),
              ],
              onChanged: (v) => setState(() => selectedType = v.toString()),
              decoration: const InputDecoration(labelText: "Issue Type"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  initialDate: DateTime.now(),
                );
                if (d != null) setState(() => selectedDate = d);
              },
              child: const Text("Select Date"),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Apply Filters"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    Query q = FirebaseFirestore.instance.collection('complaints');

    if (selectedStatus != "all") q = q.where('status', isEqualTo: selectedStatus);
    if (selectedType != "all") q = q.where('issueType', isEqualTo: selectedType);

    if (selectedDate != null) {
      final start = Timestamp.fromDate(DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day));
      final end = Timestamp.fromDate(DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day + 1));

      q = q
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end);
    }

    q = q.orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen Complaints"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: openFilter)
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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

                      Text(d['issueType'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),

                      Text(d['description'] ?? ''),
                      Text("Citizen: ${d['citizenEmail']}"),
                      Text("Status: ${d['status']}"),
                      Text("Assigned Worker: ${d['assignedWorker'] ?? 'Not Assigned'}"),

                      Row(
                        children: [
                          ElevatedButton(onPressed: () => _assign(doc.id), child: const Text("Assign")),
                          const SizedBox(width: 6),
                          ElevatedButton(onPressed: () => _updateStatus(doc.id,"in progress"), child: const Text("Progress")),
                          const SizedBox(width: 6),
                          ElevatedButton(onPressed: () => _updateStatus(doc.id,"resolved"), child: const Text("Resolved")),
                        ],
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComplaintHistoryScreen(
                                history: (d['statusHistory'] as List?) ?? [],
                              ),
                            ),
                          );
                        },
                        child: const Text("View History"),
                      ),
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
