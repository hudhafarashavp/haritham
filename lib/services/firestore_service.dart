import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_management_models.dart';
import '../models/route_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- AUTH ASSIST ---
  Future<String?> getUserEmailByUsername(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data()['email'] as String?;
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> createProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- CITIZENS ---
  Future<void> createCitizen(CitizenModel citizen) async {
    await _firestore.collection('users').doc(citizen.uid).set(citizen.toMap());
  }

  Stream<CitizenModel> streamCitizen(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => CitizenModel.fromFirestore(doc));
  }

  // --- WORKERS ---
  Future<void> createWorker(WorkerModel worker) async {
    await _firestore.collection('users').doc(worker.uid).set(worker.toMap());
  }

  Stream<List<WorkerModel>> streamWorkers() {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['hks', 'hks_worker'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkerModel.fromFirestore(doc))
              .toList(),
        );
  }

  // --- ROUTES ---
  Future<void> createRoute(RouteModel route) async {
    await _firestore.collection('routes').doc(route.routeId).set(route.toMap());
  }

  Future<void> assignRouteToWorker(String routeId, String workerId) async {
    await _firestore.collection('routes').doc(routeId).update({
      'workerId': workerId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(workerId).update({
      'assigned_route': routeId,
    });
  }

  // --- PICKUPS ---
  Future<void> createPickup(PickupModel pickup) async {
    await _firestore.collection('pickups').add(pickup.toMap());
  }

  Future<void> updatePickupStatus(String pickupId, String status) async {
    await _firestore.collection('pickups').doc(pickupId).update({
      'pickup_status': status,
    });
  }

  // --- COMPLAINTS ---
  Future<void> submitComplaint(ComplaintModel complaint) async {
    await _firestore.collection('complaints').add(complaint.toMap());
  }

  Stream<List<ComplaintModel>> streamComplaints(String citizenId) {
    return _firestore
        .collection('complaints')
        .where('citizen_id', isEqualTo: citizenId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList(),
        );
  }

  // --- NOTIFICATIONS ---
  Future<void> sendNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }

  Future<void> finalizeCitizenSignup(String uid, Map<String, dynamic> citizenData) async {
    // Save to 'citizens' collection as requested
    await _firestore.collection('citizens').doc(uid).set({
      'citizenId': uid,
      ...citizenData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also save to 'users' for auth compatibility
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': citizenData['name'],
      'email': citizenData['email'],
      'phone': citizenData['phone'],
      'username': citizenData['username'],
      'role': 'citizen',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
