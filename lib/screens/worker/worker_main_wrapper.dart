import 'package:flutter/material.dart';
// import '../../widgets/app_theme.dart';
import 'worker_home_screen.dart';
import '../citizen/citizen_calendar_screen.dart'; // Reusing the same calendar with role check
import '../../screens/worker/worker_payment_requests_screen.dart';
import '../../hks_notification_management_screen.dart';
import 'worker_profile_screen.dart';

class WorkerMainWrapper extends StatefulWidget {
  const WorkerMainWrapper({super.key});

  @override
  State<WorkerMainWrapper> createState() => _WorkerMainWrapperState();
}

class _WorkerMainWrapperState extends State<WorkerMainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const WorkerHomeScreen(),
    const CitizenCalendarScreen(), // The calendar handles role-based views
    const WorkerPaymentRequestsScreen(),
    const HksNotificationManagementScreen(),
    const WorkerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        iconSize: 28,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
