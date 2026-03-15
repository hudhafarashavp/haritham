import 'package:cloud_firestore/cloud_firestore.dart';

// PickupScheduleModel is moved to lib/models/pickup_schedule_model.dart to resolve conflicts.

class WorkerSchedule {
  final String id;
  final String workerEmail;
  final String routeId;
  final String routeName;
  final String startTime;
  final String endTime;
  final String date; // YYYY-MM-DD
  final String status; // assigned, completed
  final DateTime createdAt;

  WorkerSchedule({
    required this.id,
    required this.workerEmail,
    required this.routeId,
    required this.routeName,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory WorkerSchedule.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WorkerSchedule(
      id: doc.id,
      workerEmail: data['workerEmail'] ?? '',
      routeId: data['routeId'] ?? '',
      routeName: data['routeName'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      date: data['date'] ?? '',
      status: data['status'] ?? 'assigned',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
