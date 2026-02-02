import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'login_screen.dart';
import 'home_screen.dart';
import 'hks_home_screen.dart';
import 'panchayath_home_screen.dart';
import 'admin_home_screen.dart';
import 'startup_animation_screen.dart';

void main() async {
  // Required before using Firebase & async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase once
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartupAnimationScreen(), // startup animation
    );
  }
}

// Decides where to navigate after startup animation
class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    _decideScreen();
  }

  Future<void> _decideScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final role = prefs.getString('role');

    // Not logged in → Login
    if (!isLoggedIn || role == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Role-based navigation
    if (role == 'citizen') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (role == 'hks') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HksHomeScreen()),
      );
    } else if (role == 'panchayath') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PanchayathHomeScreen()),
      );
    } else if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
