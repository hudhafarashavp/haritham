import 'package:cloud_firestore/cloud_firestore.dart';

class PickupScheduleModel {
  final String id;
  final String citizenEmail;
  final String date; // YYYY-MM-DD
  final DateTime? routeDate;
  final String status; // pending, completed, rescheduled
  final String? area;
  final String? wasteType;
  final String? time;
  final String? routeName;
  final String? notes;

  PickupScheduleModel({
    required this.id,
    required this.citizenEmail,
    required this.date,
    this.routeDate,
    required this.status,
    this.area,
    this.wasteType,
    this.time,
    this.routeName,
    this.notes,
  });

  factory PickupScheduleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PickupScheduleModel(
      id: doc.id,
      citizenEmail: data['citizenEmail'] ?? '',
      date: data['date'] ?? '',
      routeDate: data['routeDate'] != null
          ? (data['routeDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      area: data['area'],
      wasteType: data['wasteType'],
      time: data['estimatedTime'] ?? data['time'],
      routeName: data['routeName'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'citizenEmail': citizenEmail,
      'date': date,
      'routeDate': routeDate != null ? Timestamp.fromDate(routeDate!) : null,
      'status': status,
      'area': area,
      'wasteType': wasteType,
      'estimatedTime': time,
      'routeName': routeName,
      'notes': notes,
    };
  }
}
