import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/payment_provider.dart';
import 'models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: context.read<PaymentProvider>().getCitizenPaymentsStream(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data ?? [];
          if (payments.isEmpty) {
            return const Center(child: Text("No payments found"));
          }

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final p = payments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    p.paymentMethod == 'online' ? Icons.payment : Icons.money,
                    color: Colors.green,
                  ),
                  title: Text('₹${p.amount.toStringAsFixed(2)}'),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(p.date),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          color: p.paymentStatus == 'completed'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (p.transactionId != null)
                        Text(
                          p.transactionId!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
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
