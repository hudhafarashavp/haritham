import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';
import '../models/pickup_schedule_model.dart';

class ScheduleProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<WorkerSchedule> _workerSchedules = [];
  List<PickupScheduleModel> _citizenSchedules = [];
  bool _isLoading = false;
  String? _error;

  // ========================
  // Getters
  // ========================

  List<WorkerSchedule> get workerSchedules => _workerSchedules;
  List<PickupScheduleModel> get citizenSchedules => _citizenSchedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========================
  // Private Helpers
  // ========================

  String _formatDate(DateTime date) {
    // Always use consistent format for Firestore string comparison
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ========================
  // Worker Methods
  // ========================

  // 1️⃣ Fetch worker schedules by specific date
  Future<void> fetchWorkerSchedulesByDate(String email, DateTime date) async {
    _setLoading(true);
    final dateString = _formatDate(date);

    try {
      final snapshot = await _firestore
          .collection('worker_schedules')
          .where('workerEmail', isEqualTo: email.toLowerCase())
          .where('date', isEqualTo: dateString)
          .get();

      _workerSchedules = snapshot.docs
          .map((doc) => WorkerSchedule.fromFirestore(doc))
          .toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 2️⃣ Fetch today's worker schedule
  Future<void> fetchTodayWorkerSchedule(String email) async {
    await fetchWorkerSchedulesByDate(email, DateTime.now());
  }

  // ========================
  // Citizen Methods
  // ========================

  // 3️⃣ Fetch all citizen pickup schedules (for calendar highlighting)
  Future<void> fetchCitizenSchedules(String email) async {
    _setLoading(true);

    try {
      final snapshot = await _firestore
          .collection('pickup_schedules')
          .where('citizenEmail', isEqualTo: email.toLowerCase())
          .get();

      _citizenSchedules = snapshot.docs
          .map((doc) => PickupScheduleModel.fromFirestore(doc))
          .toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ========================
  // Update Methods
  // ========================

  // 4️⃣ Update status (Worker or Citizen task)
  Future<bool> updateStatus({
    required String docId,
    required String collection,
    required String status,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _error = null;
      notifyListeners(); // Refresh UI

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ========================
  // Utility Methods
  // ========================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearWorkerSchedules() {
    _workerSchedules = [];
    notifyListeners();
  }

  void clearCitizenSchedules() {
    _citizenSchedules = [];
    notifyListeners();
  }
}
