import 'package:flutter/material.dart';
import '../models/offline_payment_request_model.dart';
import '../services/offline_payment_service.dart';
import '../services/payment_service.dart';
import '../models/payment_model.dart';

class OfflinePaymentProvider extends ChangeNotifier {
  final OfflinePaymentService _offlineService = OfflinePaymentService();
  final PaymentService _paymentService = PaymentService();

  Stream<List<OfflinePaymentRequestModel>> getWorkerRequests(String workerId) =>
      _offlineService.getRequestsByWorkerStream(workerId);

  Future<void> sendOfflineRequest(OfflinePaymentRequestModel request) async {
    await _offlineService.sendRequest(request);
    notifyListeners();
  }

  Future<void> acceptRequest(OfflinePaymentRequestModel request) async {
    // 1. Update request status
    await _offlineService.updateRequestStatus(request.requestId, 'accepted');

    // 2. Create payment record
    final payment = PaymentModel(
      paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
      citizenId: request.citizenId,
      workerId: request.hksWorkerId,
      amount: request.amount,
      paymentMethod: 'offline',
      paymentStatus: 'completed',
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _paymentService.createPayment(payment);
    notifyListeners();
  }

  Future<void> rejectRequest(String requestId) async {
    await _offlineService.updateRequestStatus(requestId, 'rejected');
    notifyListeners();
  }
}
