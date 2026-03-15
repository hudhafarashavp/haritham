import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String citizenId;
  final String workerId;
  final double amount;
  final String paymentMethod; // online, offline
  final String paymentStatus; // completed, pending
  final String? transactionId;
  final String? citizenName;
  final String? phoneNumber;
  final DateTime date;
  final DateTime createdAt;

  PaymentModel({
    required this.paymentId,
    required this.citizenId,
    required this.workerId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    this.citizenName,
    this.phoneNumber,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'citizenId': citizenId,
      'workerId': workerId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'citizenName': citizenName,
      'phoneNumber': phoneNumber,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      paymentId: id,
      citizenId: map['citizenId'] ?? '',
      workerId: map['workerId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? '',
      transactionId: map['transactionId'],
      citizenName: map['citizenName'],
      phoneNumber: map['phoneNumber'],
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
