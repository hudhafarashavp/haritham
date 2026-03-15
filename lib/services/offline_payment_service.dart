import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offline_payment_request_model.dart';

class OfflinePaymentService {
  final CollectionReference _requestCollection = FirebaseFirestore.instance
      .collection('offline_payment_requests');

  Future<void> sendRequest(OfflinePaymentRequestModel request) async {
    await _requestCollection.doc(request.requestId).set(request.toMap());
  }

  Stream<List<OfflinePaymentRequestModel>> getRequestsByWorkerStream(
    String workerId,
  ) {
    return _requestCollection
        .where('hksWorkerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => OfflinePaymentRequestModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _requestCollection.doc(requestId).update({'status': status});
  }
}
