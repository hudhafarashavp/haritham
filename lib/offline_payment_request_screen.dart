import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/offline_payment_provider.dart';
import 'models/offline_payment_request_model.dart';

class OfflinePaymentRequestScreen extends StatefulWidget {
  const OfflinePaymentRequestScreen({super.key});

  @override
  State<OfflinePaymentRequestScreen> createState() =>
      _OfflinePaymentRequestScreenState();
}

class _OfflinePaymentRequestScreenState
    extends State<OfflinePaymentRequestScreen> {
  final _amountController = TextEditingController();
  final _workerIdController =
      TextEditingController(); // In real app, this might be a dropdown
  final _workerNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Payment Request'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _workerIdController,
              decoration: const InputDecoration(labelText: 'Worker ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _workerNameController,
              decoration: const InputDecoration(labelText: 'Worker Name'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (user == null) return;

                final request = OfflinePaymentRequestModel(
                  requestId: "REQ_${DateTime.now().millisecondsSinceEpoch}",
                  citizenId: user.uid,
                  citizenName: user.displayName ?? "Citizen",
                  hksWorkerId: _workerIdController.text,
                  hksWorkerName: _workerNameController.text,
                  amount: double.tryParse(_amountController.text) ?? 0,
                  status: 'pending',
                  createdAt: DateTime.now(),
                );

                await context.read<OfflinePaymentProvider>().sendOfflineRequest(
                  request,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request Sent to Worker")),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Submit Request"),
            ),
          ],
        ),
      ),
    );
  }
}
