import 'package:flutter/material.dart';
import 'citizen_home_screen.dart';
import '../../citizen_calendar_screen.dart';
import '../../payment_screen.dart';
import '../../notification_screen.dart';
import 'citizen_settings_screen.dart';

class CitizenMainWrapper extends StatefulWidget {
  const CitizenMainWrapper({super.key});

  @override
  State<CitizenMainWrapper> createState() => _CitizenMainWrapperState();
}

class _CitizenMainWrapperState extends State<CitizenMainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CitizenHomeScreen(),
    const CitizenCalendarScreen(),
    const PaymentScreen(),
    NotificationScreen(),
    const CitizenSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
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
            label: 'Alerts',
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
