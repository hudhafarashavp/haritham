import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final CollectionReference _paymentCollection = FirebaseFirestore.instance
      .collection('payments');

  Future<void> createPayment(PaymentModel payment) async {
    await _paymentCollection.doc(payment.paymentId).set(payment.toMap());
  }

  Stream<List<PaymentModel>> getPaymentsByCitizen(String citizenId) {
    return _paymentCollection
        .where('citizenId', isEqualTo: citizenId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PaymentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Stream<List<PaymentModel>> getPaymentsByWorker(String workerId) {
    return _paymentCollection
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PaymentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Future<double> getRate({
    required String panchayathId,
    required String ward,
    required String type,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('panchayaths')
          .doc(panchayathId)
          .collection('rates')
          .doc(type)
          .get();

      if (doc.exists) {
        return (doc.data()?['amount'] ?? 100.0).toDouble();
      }
      return 100.0;
    } catch (e) {
      print("Error fetching rate: $e");
      return 100.0;
    }
  }

  Stream<List<PaymentModel>> getPendingCashPayments(String workerId) {
    return _paymentCollection
        .where('workerId', isEqualTo: workerId)
        .where('paymentMethod', isEqualTo: 'Cash')
        .where('paymentStatus', isEqualTo: 'pending_confirmation')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PaymentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Future<void> confirmPayment({
    required String paymentId,
    required String confirmedBy,
  }) async {
    await _paymentCollection.doc(paymentId).update({
      'paymentStatus': 'completed',
      'confirmedBy': confirmedBy,
    });
  }
}
