import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assign_route_screen.dart';

class ViewWorkersScreen extends StatelessWidget {
  const ViewWorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Workers"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'hks')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final workers = snapshot.data!.docs;

          if (workers.isEmpty) {
            return const Center(child: Text("No workers found"));
          }

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, i) {

              final d = workers[i].data() as Map<String, dynamic>;

              final name = d['name'] ?? '';
              final email = d['email'] ?? '';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(email),

                  trailing: IconButton(
                    icon: const Icon(Icons.assignment, color: Colors.green),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignRouteScreen(
                            workerEmail: email,
                            workerName: name,
                          ),
                        ),
                      );
                    },
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
