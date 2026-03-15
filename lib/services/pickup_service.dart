import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pickup_model.dart';

class PickupService {
  final CollectionReference _pickupCollection = FirebaseFirestore.instance
      .collection('pickup_status');

  Stream<List<PickupModel>> getPickupsByCitizenStream(String citizenId) {
    return _pickupCollection
        .where('citizenId', isEqualTo: citizenId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PickupModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Stream<List<PickupModel>> getPickupsByWorkerStream(String workerId) {
    return _pickupCollection
        .where('workerId', isEqualTo: workerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PickupModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Stream<List<PickupModel>> getPickupsByRouteStream(String routeId) {
    return _pickupCollection
        .where('routeId', isEqualTo: routeId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PickupModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Future<void> updatePickupStatus(String pickupId, String status) async {
    await _pickupCollection.doc(pickupId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reschedulePickup(String pickupId, DateTime newDate) async {
    await _pickupCollection.doc(pickupId).update({
      'status': 'rescheduled',
      'rescheduledDate': Timestamp.fromDate(newDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasPickupsForDate(String workerId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await _pickupCollection
        .where('workerId', isEqualTo: workerId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createDemoData(String workerId, {DateTime? targetDate}) async {
    final date = targetDate ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);

    final demoPickups = [
      // Ward 1
      {'wardNumber': 'Ward 1', 'houseOwnerName': 'Anil Kumar', 'houseId': '12', 'address': 'Vazhathope, Idukki'},
      {'wardNumber': 'Ward 1', 'houseOwnerName': 'Suma Teacher', 'houseId': '14', 'address': 'Vazhathope, Idukki'},
      {'wardNumber': 'Ward 1', 'houseOwnerName': 'Joseph Mathew', 'houseId': '18', 'address': 'Vazhathope, Idukki'},
      // Ward 2
      {'wardNumber': 'Ward 2', 'houseOwnerName': 'Babu Varghese', 'houseId': '4', 'address': 'Vazhathope, Idukki'},
      {'wardNumber': 'Ward 2', 'houseOwnerName': 'Latha Krishnan', 'houseId': '6', 'address': 'Vazhathope, Idukki'},
      {'wardNumber': 'Ward 2', 'houseOwnerName': 'Sunil Kumar', 'houseId': '8', 'address': 'Vazhathope, Idukki'},
      // Ward 3
      {'wardNumber': 'Ward 3', 'houseOwnerName': 'Rajan', 'houseId': '2', 'address': 'Vazhathope, Idukki'},
      {'wardNumber': 'Ward 3', 'houseOwnerName': 'Beena', 'houseId': '5', 'address': 'Vazhathope, Idukki'},
    ];

    for (var data in demoPickups) {
      // Check if already exists for this specific house on this day
      try {
        final docId = "${workerId}_${data['houseId']}_${day.year}${day.month}${day.day}";
        
        await _pickupCollection.doc(docId).set({
          'workerId': workerId,
          'routeId': 'demo_route',
          'citizenId': 'demo_${data['houseId']}',
          'houseId': data['houseId'],
          'houseOwnerName': data['houseOwnerName'],
          'wardNumber': data['wardNumber'],
          'address': data['address'],
          'date': Timestamp.fromDate(day),
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error creating demo data for ${data['houseOwnerName']}: $e");
      }
    }
  }
}
