import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/payment_provider.dart';
import 'models/payment_model.dart';
import 'package:intl/intl.dart';
import 'offline_payment_request_screen.dart';
import 'payment_history_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _panchayathName = 'Panchayath';
  String _ward = '1';
  double _amountDue = 100.0;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Mocking user profile data loading for simplicity
    setState(() => _isFetching = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _panchayathName = "Haritham Gramapanchayath";
      _isFetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCards(summary),
                const SizedBox(height: 24),
                _buildPaymentOptions(user),
                const SizedBox(height: 24),
                _buildRecentHistory(payments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, double> summary) {
    return Column(
      children: [
        Row(
          children: [
            _summaryCard('Total Pay', summary['total']!, Colors.blue),
            const SizedBox(width: 12),
            _summaryCard('Pending', summary['pending']!, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        _summaryCard(
          'Completed',
          summary['completed']!,
          Colors.green,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _summaryCard(
    String label,
    double amount,
    Color color, {
    bool fullWidth = false,
  }) {
    return Expanded(
      flex: fullWidth ? 0 : 1,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptions(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _handleOnlinePayment(user),
              icon: const Icon(Icons.flash_on),
              label: const Text('Pay Online (Razorpay)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflinePaymentRequestScreen(),
                ),
              ),
              icon: const Icon(Icons.handshake),
              label: const Text('Request Offline Payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade700),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistory(List<PaymentModel> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        if (payments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text("No recent payments")),
          )
        else
          ...payments
              .take(3)
              .map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('₹${p.amount.toStringAsFixed(2)}'),
                    subtitle: Text(DateFormat('dd MMM').format(p.date)),
                    trailing: Text(
                      p.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        color: p.paymentStatus == 'completed'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  void _handleOnlinePayment(User user) {
    context.read<PaymentProvider>().processOnlinePayment(
      citizenId: user.uid,
      workerId: "SYSTEM",
      amount: 100.0, // Should be dynamic in real use
      contact: user.phoneNumber ?? "9999999999",
      email: user.email ?? "test@haritham.com",
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Razorpay Checkout Initiated...")),
    );
  }
}
