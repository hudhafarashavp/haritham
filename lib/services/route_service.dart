import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';
import '../models/pickup_schedule_model.dart';

class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // HKS Worker: Fetch routes filtered by workerId and date >= today
  Stream<List<RouteModel>> getWorkerRoutes(String workerId) {
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

  // Citizen: Fetch pickup schedules from the dedicated collection
  Stream<List<PickupScheduleModel>> getCitizenPickupSchedules(String email) {
    return _firestore
        .collection('pickup_schedules')
        .where('citizenEmail', isEqualTo: email.toLowerCase())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PickupScheduleModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Admin: Create
  Future<void> createRoute(RouteModel route) async {
    final routeRef = _firestore.collection('routes').doc();
    final finalRoute = route.copyWith(routeId: routeRef.id);

    await routeRef.set(finalRoute.toMap());

    // If a worker is assigned, update their profile
    if (finalRoute.workerId != null && finalRoute.workerId!.isNotEmpty) {
      await _updateWorkerRoute(finalRoute.workerId!, finalRoute.routeId);
    }
  }

  Future<void> _updateWorkerRoute(String workerId, String routeId) async {
    // Update in users collection
    await _firestore.collection('users').doc(workerId).update({
      'assignedRouteId': routeId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also update in workers collection if it exists
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'assignedRouteId': routeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore if workers collection doesn't have the doc
    }
  }
}
