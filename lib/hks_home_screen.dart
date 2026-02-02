import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'notification_screen.dart';
import 'create_notification_screen.dart';
import 'hks_notification_management_screen.dart';
import 'hks_history_screen.dart';
import 'hks_status_screen.dart';
import 'create_complaint_screen.dart';

class HksHomeScreen extends StatelessWidget {

  // ✅ ONLY FIXED LINE
  const HksHomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationScreen()),
    );
  }

  void _openCreateNotification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateNotificationScreen()),
    );
  }

  void _openManageNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HksNotificationManagementScreen()),
    );
  }

  void _openCreateComplaint(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateComplaintScreen()),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HksHistoryScreen()),
    );
  }

  void _openStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HksStatusScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('HKS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _openNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Text(
              'HKS Home',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => _openCreateNotification(context),
              child: const Text('Create Notification'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _openManageNotifications(context),
              child: const Text('Manage My Notifications'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _openCreateComplaint(context),
              child: const Text('Create Complaint'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _openHistory(context),
              child: const Text('My Complaint History'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _openStatus(context),
              child: const Text('My Complaint Status'),
            ),
          ],
        ),
      ),
    );
  }
}
