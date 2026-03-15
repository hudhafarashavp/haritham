import 'package:cloud_firestore/cloud_firestore.dart';

class RouteStop {
  final String stopName;
  final String status; // Pending, Completed, Skipped
  final double? latitude;
  final double? longitude;
  final String? citizenId;
  final String? citizenEmail;

  RouteStop({
    required this.stopName,
    this.status = 'Pending',
    this.latitude,
    this.longitude,
    this.citizenId,
    this.citizenEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'citizenId': citizenId,
      'citizenEmail': citizenEmail,
    };
  }

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      stopName: map['stopName'] ?? map['locationName'] ?? '',
      status: map['status'] ?? 'Pending',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      citizenId: map['citizenId'],
      citizenEmail: map['citizenEmail'],
    );
  }

  RouteStop copyWith({
    String? stopName,
    String? status,
    double? latitude,
    double? longitude,
    String? citizenId,
    String? citizenEmail,
  }) {
    return RouteStop(
      stopName: stopName ?? this.stopName,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      citizenId: citizenId ?? this.citizenId,
      citizenEmail: citizenEmail ?? this.citizenEmail,
    );
  }
}

class RouteModel {
  final String routeId;
  final String panchayathId;
  final String routeName; // New
  final String? workerId;
  final String? assignedWorkerName; // New
  final String? routeType; // Route 1, Route 2, Route 3
  final String? startStop; // New
  final String? endStop; // New
  final List<String> intermediateStops; // New: Simple list of strings
  final DateTime routeDate;
  final String startTime; // HH:mm
  final List<RouteStop> stops; // Keep for backward compatibility/legacy logic
  final double totalDistance;
  final String estimatedTime;
  final String status; // Scheduled, Ongoing, Completed
  final String wasteType; // General, Plastic, etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get routeNumber => routeType;

  RouteModel({
    required this.routeId,
    required this.panchayathId,
    this.routeName = '', // New
    this.workerId,
    this.assignedWorkerName,
    this.routeType,
    this.startStop,
    this.endStop,
    this.intermediateStops = const [],
    required this.routeDate,
    required this.startTime,
    required this.stops,
    this.totalDistance = 0.0,
    this.estimatedTime = '',
    this.status = 'Scheduled',
    this.wasteType = 'General Waste',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'panchayathId': panchayathId,
      'routeName': routeName,
      'workerId': workerId,
      'assignedWorkerId': workerId, // Alias for compliance
      'assignedWorkerName': assignedWorkerName,
      'routeType': routeType,
      'routeNumber': routeType, // Alias requested in task
      'startStop': startStop,
      'startLocation': startStop, // Requested alias
      'endStop': endStop,
      'endLocation': endStop, // Requested alias
      'intermediateStops': intermediateStops,
      'stops': stops.map((s) => s.toMap()).toList(),
      'routeDate': Timestamp.fromDate(routeDate),
      'startTime': startTime,
      'totalDistance': totalDistance,
      'estimatedDistance': totalDistance, // Alias for compliance
      'estimatedTime': estimatedTime,
      'status': status,
      'wasteType': wasteType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RouteModel copyWith({
    String? routeId,
    String? panchayathId,
    String? routeName,
    String? workerId,
    String? assignedWorkerName,
    String? routeType,
    String? startStop,
    String? endStop,
    List<String>? intermediateStops,
    DateTime? routeDate,
    String? startTime,
    List<RouteStop>? stops,
    double? totalDistance,
    String? estimatedTime,
    String? status,
    String? wasteType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteModel(
      routeId: routeId ?? this.routeId,
      panchayathId: panchayathId ?? this.panchayathId,
      routeName: routeName ?? this.routeName,
      workerId: workerId ?? this.workerId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      routeType: routeType ?? this.routeType,
      startStop: startStop ?? this.startStop,
      endStop: endStop ?? this.endStop,
      intermediateStops: intermediateStops ?? this.intermediateStops,
      routeDate: routeDate ?? this.routeDate,
      startTime: startTime ?? this.startTime,
      stops: stops ?? this.stops,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status: status ?? this.status,
      wasteType: wasteType ?? this.wasteType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return RouteModel(
      routeId: doc.id,
      panchayathId: data['panchayathId'] ?? '',
      routeName: data['routeName'] ?? '',
      workerId: data['workerId'],
      assignedWorkerName: data['assignedWorkerName'],
      routeType: data['routeType'] ?? data['routeNumber'],
      startStop: data['startStop'],
      endStop: data['endStop'],
      intermediateStops: List<String>.from(data['intermediateStops'] ?? []),
      routeDate: parseDate(data['routeDate']),
      startTime: data['startTime'] ?? '08:00',
      stops: (data['stops'] as List? ?? [])
          .map((s) => RouteStop.fromMap(s as Map<String, dynamic>))
          .toList(),
      totalDistance: (data['totalDistance'] as num? ?? 0.0).toDouble(),
      estimatedTime: data['estimatedTime'] ?? '',
      status: data['status'] ?? 'Scheduled',
      wasteType: data['wasteType'] ?? 'General Waste',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
