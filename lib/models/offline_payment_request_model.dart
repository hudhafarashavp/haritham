import 'package:cloud_firestore/cloud_firestore.dart';

class OfflinePaymentRequestModel {
  final String requestId;
  final String citizenId;
  final String citizenName;
  final String hksWorkerId;
  final String hksWorkerName;
  final double amount;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  OfflinePaymentRequestModel({
    required this.requestId,
    required this.citizenId,
    required this.citizenName,
    required this.hksWorkerId,
    required this.hksWorkerName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'citizenId': citizenId,
      'citizenName': citizenName,
      'hksWorkerId': hksWorkerId,
      'hksWorkerName': hksWorkerName,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OfflinePaymentRequestModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return OfflinePaymentRequestModel(
      requestId: id,
      citizenId: map['citizenId'] ?? '',
      citizenName: map['citizenName'] ?? '',
      hksWorkerId: map['hksWorkerId'] ?? '',
      hksWorkerName: map['hksWorkerName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
