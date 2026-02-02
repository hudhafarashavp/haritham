import 'package:flutter/material.dart';

class ComplaintHistoryScreen extends StatelessWidget {
  final List history;

  const ComplaintHistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint History"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final h = history[index];

          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(h['status']),
            subtitle: Text(h['time'].toDate().toString()),
          );
        },
      ),
    );
  }
}
