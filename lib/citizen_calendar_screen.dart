import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pickup_calendar_screen.dart';

class CitizenCalendarScreen extends StatelessWidget {
  const CitizenCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return PickupCalendarScreen(isWorker: false, userId: user?.uid ?? '');
  }
}
