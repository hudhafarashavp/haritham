import 'package:cloud_firestore/cloud_firestore.dart';

class CitizenModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;
  final String houseNumber;
  final String wardNumber;
  final String panchayat;
  final DateTime createdAt;

  CitizenModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.latitude,
    this.longitude,
    required this.houseNumber,
    required this.wardNumber,
    required this.panchayat,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'location': latitude != null && longitude != null
          ? GeoPoint(latitude!, longitude!)
          : null,
      'houseNumber': houseNumber,
      'ward_number': wardNumber,
      'panchayat': panchayat,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory CitizenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as GeoPoint?;
    return CitizenModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      latitude: location?.latitude,
      longitude: location?.longitude,
      houseNumber: data['houseNumber'] ?? data['house_number'] ?? '',
      wardNumber: data['ward_number'] ?? '',
      panchayat: data['panchayat'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class WorkerModel {
  final String uid;
  final String name;
  final String workerId;
  final String phone;
  final String? assignedRoute;
  final String role;
  final bool isActive;

  WorkerModel({
    required this.uid,
    required this.name,
    required this.workerId,
    required this.phone,
    this.assignedRoute,
    this.role = 'hks',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'worker_id': workerId,
      'phone': phone,
      'assigned_route': assignedRoute,
      'role': role,
      'status': isActive ? 'active' : 'inactive',
    };
  }

  factory WorkerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkerModel(
      uid: doc.id,
      name: data['name'] ?? '',
      workerId: data['worker_id'] ?? '',
      phone: data['phone'] ?? '',
      assignedRoute: data['assigned_route'],
      role: data['role'] ?? 'hks',
      isActive: data['status'] == 'active',
    );
  }
}

class PickupModel {
  final String pickupId;
  final String citizenId;
  final String routeId;
  final String status; // pending / completed
  final DateTime pickupDate;
  final String workerId;

  PickupModel({
    required this.pickupId,
    required this.citizenId,
    required this.routeId,
    required this.status,
    required this.pickupDate,
    required this.workerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'pickup_id': pickupId,
      'citizen_id': citizenId,
      'route_id': routeId,
      'pickup_status': status,
      'pickup_date': Timestamp.fromDate(pickupDate),
      'worker_id': workerId,
    };
  }

  factory PickupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PickupModel(
      pickupId: doc.id,
      citizenId: data['citizen_id'] ?? '',
      routeId: data['route_id'] ?? '',
      status: data['pickup_status'] ?? 'pending',
      pickupDate: (data['pickup_date'] as Timestamp).toDate(),
      workerId: data['worker_id'] ?? '',
    );
  }
}

class ComplaintModel {
  final String complaintId;
  final String citizenId;
  final String description;
  final String location;
  final String status; // open / resolved
  final DateTime createdAt;

  ComplaintModel({
    required this.complaintId,
    required this.citizenId,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'complaint_id': complaintId,
      'citizen_id': citizenId,
      'description': description,
      'location': location,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      complaintId: doc.id,
      citizenId: data['citizen_id'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}

class NotificationModel {
  final String message;
  final String userId;
  final String type;
  final DateTime createdAt;

  NotificationModel({
    required this.message,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'user_id': userId,
      'type': type,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      message: data['message'] ?? '',
      userId: data['user_id'] ?? '',
      type: data['type'] ?? 'general',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}
