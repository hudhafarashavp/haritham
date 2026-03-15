import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Stream<List<PaymentModel>> getCitizenPaymentsStream(String citizenId) =>
      _paymentService.getPaymentsByCitizen(citizenId);

  Future<double> fetchDynamicRate({
    required String panchayathId,
    required String ward,
    required String type,
  }) async {
    return await _paymentService.getRate(
      panchayathId: panchayathId,
      ward: ward,
      type: type,
    );
  }

  Future<void> processOnlinePayment({
    required String citizenId,
    required String workerId,
    required double amount,
    required String contact,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    // In a real app, you'd initialize RazorpayService here
    // or use a callback mechanism to handle success/failure.
    // For this implementation, we'll simulate the checkout flow logic.

    print("Initiating Razorpay for $amount");
    // Simulate successful payment record creation after Razorpay success
    final payment = PaymentModel(
      paymentId: "PAY_${DateTime.now().millisecondsSinceEpoch}",
      citizenId: citizenId,
      workerId: workerId,
      amount: amount,
      paymentMethod: 'online',
      paymentStatus: 'completed',
      transactionId: "T_${DateTime.now().millisecondsSinceEpoch}",
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _paymentService.createPayment(payment);
    _isLoading = false;
    notifyListeners();
  }

  // Summary Calculation
  Map<String, double> calculateSummary(List<PaymentModel> payments) {
    double total = 0;
    double completed = 0;
    double pending = 0;

    for (var p in payments) {
      total += p.amount;
      if (p.paymentStatus == 'completed') {
        completed += p.amount;
      } else if (p.paymentStatus == 'pending') {
        pending += p.amount;
      }
    }

    return {'total': total, 'completed': completed, 'pending': pending};
  }

  Stream<List<PaymentModel>> getPendingCashPaymentsStream(String workerId) =>
      _paymentService.getPendingCashPayments(workerId);

  Future<void> confirmCashPayment({
    required String paymentId,
    required String confirmedBy,
  }) async {
    await _paymentService.confirmPayment(
      paymentId: paymentId,
      confirmedBy: confirmedBy,
    );
    notifyListeners();
  }
}
