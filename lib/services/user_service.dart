import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Create Worker
  Future<void> createWorker({
    required String uid,
    required String name,
    required String username,
    required String email,
    required String phone,
    String role = 'worker',
  }) async {
    final workerData = {
      'uid': uid,
      'name': name,
      'username': username.toLowerCase(),
      'email': email.toLowerCase(),
      'phone': phone,
      'role': role,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Save to users collection (primary)
    await _firestore.collection('users').doc(uid).set(workerData);

    // Save to workers collection (requested secondary)
    await _firestore.collection('workers').doc(uid).set(workerData);
  }

  // 2. Get All Workers
  Future<List<Map<String, dynamic>>> getWorkers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', whereIn: ['worker', 'hks', 'hks_worker'])
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // 3. Get User by Username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  // 4. Get User by Email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  // Legacy/Helper for profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Legacy/Helper for location
  Future<void> updateHouseLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'houseLocation': {'latitude': latitude, 'longitude': longitude},
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
