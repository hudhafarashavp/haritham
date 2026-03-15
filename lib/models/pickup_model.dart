import 'package:cloud_firestore/cloud_firestore.dart';

class PickupModel {
  final String pickupId;
  final String routeId;
  final String workerId;
  final String citizenId;
  final DateTime scheduledDate;
  final String status; // completed, pending, missed, rescheduled
  final DateTime? rescheduledDate;
  final DateTime updatedAt;

  final String? location;
  final String? workerName;
  final String? wardNumber;
  final String? houseOwnerName;
  final String? houseId;

  PickupModel({
    required this.pickupId,
    required this.routeId,
    required this.workerId,
    required this.citizenId,
    required this.scheduledDate,
    required this.status,
    this.rescheduledDate,
    required this.updatedAt,
    this.location,
    this.workerName,
    this.wardNumber,
    this.houseOwnerName,
    this.houseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'pickupId': pickupId,
      'routeId': routeId,
      'workerId': workerId,
      'citizenId': citizenId,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status,
      'rescheduledDate': rescheduledDate != null
          ? Timestamp.fromDate(rescheduledDate!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'workerName': workerName,
      'wardNumber': wardNumber,
      'houseOwnerName': houseOwnerName,
      'houseId': houseId,
    };
  }

  factory PickupModel.fromMap(Map<String, dynamic> map, String id) {
    return PickupModel(
      pickupId: id,
      routeId: map['routeId'] ?? '',
      workerId: map['workerId'] ?? '',
      citizenId: map['citizenId'] ?? '',
      scheduledDate: _parseDate(map['scheduledDate'] ?? map['date']),
      status: map['status'] ?? 'upcoming',
      rescheduledDate: map['rescheduledDate'] != null
          ? _parseDate(map['rescheduledDate'])
          : null,
      updatedAt: _parseDate(map['updatedAt'] ?? map['createdAt']),
      location: map['location'] ?? map['address'],
      workerName: map['workerName'],
      wardNumber: map['wardNumber'] ?? map['ward_number'],
      houseOwnerName: map['houseOwnerName'] ?? map['house_owner_name'],
      houseId: map['houseId'] ?? map['house_id'],
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}
