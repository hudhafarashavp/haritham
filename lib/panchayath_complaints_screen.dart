import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'filter_bottom_sheet.dart';

class PanchayathComplaintsScreen extends StatefulWidget {
  const PanchayathComplaintsScreen({super.key});

  @override
  State<PanchayathComplaintsScreen> createState() =>
      _PanchayathComplaintsScreenState();
}

class _PanchayathComplaintsScreenState
    extends State<PanchayathComplaintsScreen> {

  String selectedStatus = "all";
  DateTime? selectedDate;

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      "status": status,
      "statusHistory": FieldValue.arrayUnion([
        {"status": status, "time": Timestamp.now()}
      ])
    });
  }

  void openFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FilterBottomSheet(
        selectedStatus: selectedStatus,
        selectedDate: selectedDate,
        onApply: (status, date) {
          setState(() {
            selectedStatus = status;
            selectedDate = date;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    Query q = FirebaseFirestore.instance.collection('complaints');

    if (selectedStatus != "all") {
      q = q.where('status', isEqualTo: selectedStatus);
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

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaints"));
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

                      const SizedBox(height: 8),

                      TextFormField(
                        initialValue: d['panchayathRemark'] ?? '',
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Panchayath Remark',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          FirebaseFirestore.instance
                              .collection('complaints')
                              .doc(doc.id)
                              .update({'panchayathRemark': value});
                        },
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(doc.id, "in progress"),
                              child: const Text("Progress")),

                          const SizedBox(width: 6),

                          ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(doc.id, "resolved"),
                              child: const Text("Resolved")),
                        ],
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
