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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartupAnimationScreen(),
    );
  }
}

// ================= SPLASH DECIDER =================

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
    if (!mounted) return;

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final role = prefs.getString('role');

    if (!isLoggedIn || role == null) {
      _go(const LoginScreen());
      return;
    }

    if (role == 'citizen') {
      _go(const HomeScreen());
    } else if (role == 'hks') {
      _go(const HksHomeScreen());
    } else if (role == 'panchayath') {
      _go(const PanchayathHomeScreen());
    } else if (role == 'admin') {
      _go(const AdminHomeScreen());
    } else {
      _go(const LoginScreen());
    }
  }

  void _go(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
