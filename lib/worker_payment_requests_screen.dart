import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/offline_payment_provider.dart';
import 'models/offline_payment_request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerPaymentRequestsScreen extends StatelessWidget {
  const WorkerPaymentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Payment Requests'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OfflinePaymentRequestModel>>(
        stream: context.read<OfflinePaymentProvider>().getWorkerRequests(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(req.citizenName),
                  subtitle: Text('Amount: ₹${req.amount}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => context
                            .read<OfflinePaymentProvider>()
                            .acceptRequest(req),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => context
                            .read<OfflinePaymentProvider>()
                            .rejectRequest(req.requestId),
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
