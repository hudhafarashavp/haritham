import 'package:flutter/material.dart';
import '../models/pickup_model.dart';
import '../services/pickup_service.dart';

class PickupProvider extends ChangeNotifier {
  final PickupService _pickupService = PickupService();

  Stream<List<PickupModel>> getPickupsByCitizenStream(String citizenId) =>
      _pickupService.getPickupsByCitizenStream(citizenId);

  Stream<List<PickupModel>> getPickupsByWorkerStream(String workerId) =>
      _pickupService.getPickupsByWorkerStream(workerId);

  Stream<List<PickupModel>> getPickupsByRouteStream(String routeId) =>
      _pickupService.getPickupsByRouteStream(routeId);

  Future<void> updateStatus(String pickupId, String status) async {
    await _pickupService.updatePickupStatus(pickupId, status);
    notifyListeners();
  }

  Future<void> reschedulePickup(String pickupId, DateTime newDate) async {
    await _pickupService.reschedulePickup(pickupId, newDate);
    notifyListeners();
  }

  Future<bool> hasPickupsForDate(String workerId, DateTime date) =>
      _pickupService.hasPickupsForDate(workerId, date);

  Future<void> createDemoData(String workerId, {DateTime? targetDate}) async {
    await _pickupService.createDemoData(workerId, targetDate: targetDate);
    notifyListeners();
  }
}
