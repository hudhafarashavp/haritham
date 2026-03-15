import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/payment_provider.dart';
import 'models/payment_model.dart';

class HksPaymentConfirmationScreen extends StatefulWidget {
  final String workerUsername;

  const HksPaymentConfirmationScreen({super.key, required this.workerUsername});

  @override
  State<HksPaymentConfirmationScreen> createState() =>
      _HksPaymentConfirmationScreenState();
}

class _HksPaymentConfirmationScreenState
    extends State<HksPaymentConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Pending Cash Collections'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: context.read<PaymentProvider>().getPendingCashPaymentsStream(
          widget.workerUsername,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final pendingPayments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingPayments.length,
            itemBuilder: (context, index) {
              final payment = pendingPayments[index];
              return _buildPaymentCard(context, payment);
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.citizenName ?? 'Unknown Citizen',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(payment.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Requested: ${DateFormat('dd MMM, hh:mm a').format(payment.createdAt)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Citizen Ph: ${payment.phoneNumber ?? "N/A"}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmPayment(context, payment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending cash confirmations.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment(
    BuildContext context,
    PaymentModel payment,
  ) async {
    try {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      await provider.confirmCashPayment(
        paymentId: payment.paymentId,
        confirmedBy: widget.workerUsername,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment from ${payment.citizenName ?? "Citizen"} confirmed!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
