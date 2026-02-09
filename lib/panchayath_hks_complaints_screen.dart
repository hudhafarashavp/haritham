import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PanchayathHksComplaintsScreen extends StatefulWidget {
  const PanchayathHksComplaintsScreen({super.key});

  @override
  State<PanchayathHksComplaintsScreen> createState() =>
      _PanchayathHksComplaintsScreenState();
}

class _PanchayathHksComplaintsScreenState
    extends State<PanchayathHksComplaintsScreen> {

  String selectedStatus = "all";
  String selectedType = "all";
  DateTime? selectedDate;

  void openFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text(
              "Filters",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

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

            DropdownButtonFormField(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "all", child: Text("All Types")),
                DropdownMenuItem(value: "Burning waste", child: Text("Burning waste")),
                DropdownMenuItem(value: "Overflowing bin", child: Text("Overflowing bin")),
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
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (d != null) setState(() => selectedDate = d);
              },
              child: Text(
                selectedDate == null
                    ? "Select Date"
                    : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
              ),
            ),

            const SizedBox(height: 10),

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

    Query q = FirebaseFirestore.instance.collection('hks_complaints');

    if (selectedStatus != "all") {
      q = q.where('status', isEqualTo: selectedStatus);
    }

    if (selectedType != "all") {
      q = q.where('issueType', isEqualTo: selectedType);
    }

    if (selectedDate != null) {
      final start = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );

      final end = start.add(const Duration(days: 1));

      q = q
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt',
          isLessThan: Timestamp.fromDate(end));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("HKS Complaints"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: openFilter,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaints"));
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
                        data['issueType'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(data['description'] ?? ''),

                      const SizedBox(height: 6),

                      Text("Status: ${data['status']}"),

                      const SizedBox(height: 10),

                      if (data['status'] == "pending")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('hks_complaints')
                                  .doc(docs[index].id)
                                  .update({'status': 'resolved'});
                            },
                            child: const Text("Mark Resolved"),
                          ),
                        ),
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
