import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pickup_calendar_screen.dart';

class CitizenCalendarScreen extends StatelessWidget {
  const CitizenCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final prefs = snapshot.data!;
        final role = prefs.getString('role');
        final user = FirebaseAuth.instance.currentUser;

        return PickupCalendarScreen(
          isWorker: role == 'hks_worker',
          userId: user?.uid ?? '',
        );
      },
    );
  }
}
