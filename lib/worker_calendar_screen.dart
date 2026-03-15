import 'package:flutter/material.dart';
import 'pickup_calendar_screen.dart';

class WorkerCalendarScreen extends StatelessWidget {
  final String workerId;
  const WorkerCalendarScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return PickupCalendarScreen(isWorker: true, userId: workerId);
  }
}
