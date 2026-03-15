import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import '../../offline_payment_request_screen.dart';
import '../../payment_history_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: context.read<PaymentProvider>().getCitizenPaymentsStream(
          user.uid,
        ),
        builder: (context, snapshot) {
          final payments = snapshot.data ?? [];
          final summary = context.read<PaymentProvider>().calculateSummary(
            payments,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Balance',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _BalanceCard(
                      label: "Pending",
                      amount: summary['pending']!,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _BalanceCard(
                      label: "Total Paid",
                      amount: summary['total']!,
                      color: AppTheme.harithamGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Payment Methods',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                HarithamCard(
                  onTap: () => _handleOnlinePayment(user),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.flash_on, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pay Online",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Fast & Secure via Razorpay",
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.borderGrey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                HarithamCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OfflinePaymentRequestScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.handshake_outlined,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Offline Payment",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Request pickup worker to collect",
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.borderGrey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentHistoryScreen(),
                        ),
                      ),
                      child: const Text("See All"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  const Center(
                    child: Text(
                      "No transactions yet",
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  )
                else
                  ...payments.take(5).map((p) => _TransactionTile(payment: p)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleOnlinePayment(User user) {
    context.read<PaymentProvider>().processOnlinePayment(
      citizenId: user.uid,
      workerId: "SYSTEM",
      amount: 100.0,
      contact: user.phoneNumber ?? "9999999999",
      email: user.email ?? "test@haritham.com",
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Checkout Initiated...")));
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "₹${amount.toInt()}",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PaymentModel payment;
  const _TransactionTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGrey.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.softGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_outlined, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Fee",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(payment.date),
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${payment.amount.toInt()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                payment.paymentStatus.toUpperCase(),
                style: TextStyle(
                  color: payment.paymentStatus == 'completed'
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
