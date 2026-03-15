import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';

class RouteProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;
  List<RouteModel> _routes = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<RouteModel> get routes => _routes;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Create Route
  Future<String?> addRoute(RouteModel route) async {
    _setLoading(true);
    try {
      final docRef = await _firestore.collection('routes').add(route.toMap());
      final routeId = docRef.id;

      await _syncAllSchedules(routeId, route);

      // Add Notification for Worker
      if (route.workerId != null) {
        await _firestore.collection('notifications').add({
          'title': 'New Route Assigned',
          'message':
              'You have been assigned to ${route.routeName} on ${DateFormat('EEE, MMM d').format(route.routeDate)}',
          'target': 'hks',
          'targetId': route.workerId,
          'createdBy': 'panchayath',
          'createdAt': FieldValue.serverTimestamp(),
          'viewedBy': {'hks': false},
        });
      }

      _error = null;
      return routeId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update Route
  Future<bool> updateRoute(RouteModel route) async {
    _setLoading(true);
    try {
      if (route.routeId.isEmpty) {
        throw Exception("Cannot update route with empty ID");
      }
      await _firestore
          .collection('routes')
          .doc(route.routeId)
          .update(route.toMap());

      await _syncAllSchedules(route.routeId, route);

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch Routes by Panchayath (One-time)
  Future<void> fetchRoutesByPanchayath(String panchayathId) async {
    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('panchayathId', isEqualTo: panchayathId)
          .orderBy('routeDate', descending: true)
          .get();

      _routes = snapshot.docs
          .map((doc) => RouteModel.fromFirestore(doc))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Watch Routes by Panchayath (Stream)
  Stream<List<RouteModel>> watchRoutesByPanchayath(String panchayathId) {
    return _firestore
        .collection('routes')
        .where('panchayathId', isEqualTo: panchayathId)
        .orderBy('routeDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RouteModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Watch Routes by Worker (Stream)
  Stream<List<RouteModel>> watchRoutesByWorker(String workerId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('routes')
        .where('workerId', isEqualTo: workerId)
        .where('routeDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('routeDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RouteModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Watch specific Route (Stream)
  Stream<RouteModel?> watchRouteById(String routeId) {
    return _firestore.collection('routes').doc(routeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RouteModel.fromFirestore(doc);
    });
  }

  // Update Route Status
  Future<bool> updateRouteStatus(String routeId, String status) async {
    try {
      await _firestore.collection('routes').doc(routeId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Assign Worker to Route
  Future<bool> assignWorker(String routeId, String workerId) async {
    try {
      await _firestore.collection('routes').doc(routeId).update({
        'workerId': workerId,
        'status': 'Scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update Stop Status
  Future<bool> updateStopStatus(
    String routeId,
    int stopIndex,
    String status,
  ) async {
    try {
      final routeDoc = await _firestore.collection('routes').doc(routeId).get();
      if (!routeDoc.exists) return false;

      final route = RouteModel.fromFirestore(routeDoc);
      final updatedStops = List<RouteStop>.from(route.stops);

      // Update the specific stop
      updatedStops[stopIndex] = updatedStops[stopIndex].copyWith(
        status: status,
      );

      // check if all stops are completed
      final allCompleted = updatedStops.every((s) => s.status == 'Completed');
      final newRouteStatus = allCompleted ? 'Completed' : 'Ongoing';

      await _firestore.collection('routes').doc(routeId).update({
        'stops': updatedStops.map((s) => s.toMap()).toList(),
        'status': newRouteStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete Route
  Future<bool> deleteRoute(String routeId) async {
    try {
      await _firestore.collection('routes').doc(routeId).delete();
      _error = null;
      _routes.removeWhere((r) => r.routeId == routeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Unified Sync for all schedules (Worker & Citizens)
  Future<void> _syncAllSchedules(String routeId, RouteModel route) async {
    final dateString = DateFormat('yyyy-MM-dd').format(route.routeDate);

    // 1. Sync Worker Schedule
    if (route.workerId != null) {
      // Update legacy user doc fields
      await _firestore.collection('users').doc(route.workerId).update({
        'assignedRouteId': routeId,
        'assignedRouteNumber': route.routeType,
        'assignedStartStop': route.startStop,
        'assignedEndStop': route.endStop,
        'assignedIntermediateStops': route.intermediateStops,
        'routeStartDate': Timestamp.fromDate(route.routeDate),
        'routeEndDate': Timestamp.fromDate(route.routeDate),
        'routeStatus': route.status,
      });

      // Get worker email for the specific schedule collection
      final workerDoc = await _firestore
          .collection('users')
          .doc(route.workerId)
          .get();
      final workerEmail = workerDoc.data()?['email'] ?? '';

      // Update or Create Worker Schedule document
      await _firestore
          .collection('worker_schedules')
          .doc('${route.workerId}_$dateString')
          .set({
            'workerEmail': workerEmail,
            'routeId': routeId,
            'routeName': route.routeType ?? 'Route',
            'startTime': route.startTime,
            'endTime': '', // To be filled later
            'date': dateString,
            'status': route.status == 'Completed' ? 'completed' : 'assigned',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // 1b. Sync Task Collection
      await _firestore
          .collection('tasks')
          .doc('${routeId}_${route.workerId}')
          .set({
            'taskId': '${routeId}_${route.workerId}',
            'workerId': route.workerId,
            'routeId': routeId,
            'routeNumber': route.routeType ?? 'Route',
            'routeDate': Timestamp.fromDate(route.routeDate),
            'status': route.status == 'Completed' ? 'completed' : 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // 1c. Update Workers Collection (assignedRoutes array)
      await _firestore.collection('workers').doc(route.workerId).set({
        'workerId': route.workerId,
        'workerName': route.assignedWorkerName ?? 'Worker',
        'assignedRoutes': FieldValue.arrayUnion([routeId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 2. Sync Citizen Pickup Schedules
    for (var stop in route.stops) {
      if (stop.citizenEmail != null && stop.citizenEmail!.isNotEmpty) {
        await _firestore
            .collection('pickup_schedules')
            .doc('${stop.citizenId}_$dateString')
            .set({
              'citizenEmail': stop.citizenEmail,
              'date': dateString,
              'status': stop.status == 'Completed'
                  ? 'completed'
                  : (route.status == 'Completed' ? 'skipped' : 'pending'),
              'routeName': route.routeType ?? 'Waste Collection',
              'notes': route.wasteType,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    }
  }

  // Update Task Status
  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
