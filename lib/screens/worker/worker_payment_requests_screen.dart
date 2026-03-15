import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/offline_payment_provider.dart';
import '../../models/offline_payment_request_model.dart';

class WorkerPaymentRequestsScreen extends StatelessWidget {
  const WorkerPaymentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Requests')),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 64,
                    color: AppTheme.borderGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pending requests",
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.padding),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return HarithamCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.softGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.citizenName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Amount: ₹${req.amount}",
                            style: const TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () => context
                              .read<OfflinePaymentProvider>()
                              .acceptRequest(req),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => context
                              .read<OfflinePaymentProvider>()
                              .rejectRequest(req.requestId),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
