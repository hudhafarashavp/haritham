import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignRouteScreen extends StatefulWidget {
  final String workerEmail;
  final String workerName;

  const AssignRouteScreen({
    super.key,
    required this.workerEmail,
    required this.workerName,
  });

  @override
  State<AssignRouteScreen> createState() => _AssignRouteScreenState();
}

class _AssignRouteScreenState extends State<AssignRouteScreen> {

  final routeIdController = TextEditingController();
  final routeNameController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  bool loading = false;

  Future<void> assignRoute() async {

    if (routeIdController.text.isEmpty ||
        routeNameController.text.isEmpty ||
        startTimeController.text.isEmpty ||
        endTimeController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    final today =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection('worker_schedules').add({

      'workerEmail': widget.workerEmail,
      'workerName': widget.workerName,

      'routeId': routeIdController.text.trim(),
      'routeName': routeNameController.text.trim(),

      'startTime': startTimeController.text.trim(),
      'endTime': endTimeController.text.trim(),

      'date': today,
      'status': 'assigned',
      'createdAt': Timestamp.now(),
    });

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    routeIdController.dispose();
    routeNameController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Route"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Text(
              "Worker: ${widget.workerName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: routeIdController,
              decoration: const InputDecoration(labelText: "Route ID"),
            ),

            TextField(
              controller: routeNameController,
              decoration: const InputDecoration(labelText: "Route Name"),
            ),

            TextField(
              controller: startTimeController,
              decoration: const InputDecoration(labelText: "Start Time"),
            ),

            TextField(
              controller: endTimeController,
              decoration: const InputDecoration(labelText: "End Time"),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: loading ? null : assignRoute,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Assign Worker"),
            ),
          ],
        ),
      ),
    );
  }
}
