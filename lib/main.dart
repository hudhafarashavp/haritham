import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'screens/citizen/citizen_main_wrapper.dart';
import 'screens/worker/worker_main_wrapper.dart';
import 'panchayath_home_screen.dart';
import 'admin_home_screen.dart';

import 'package:provider/provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/route_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/pickup_provider.dart';
import 'providers/offline_payment_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PickupProvider()),
        ChangeNotifierProvider(create: (_) => OfflinePaymentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashDecider(),
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

    // Fast path: If SharedPreferences says we are not logged in, go to login immediately
    if (!isLoggedIn || role == null) {
      _go(const LoginScreen());
      return;
    }

    // Check Firebase Auth synchronously
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is likely still logged in, proceed to role routing
      _routeByRole(role);
    } else {
      // Wait once for auth state to confirm session
      final confirmedUser = await FirebaseAuth.instance
          .authStateChanges()
          .first;
      if (confirmedUser != null) {
        _routeByRole(role);
      } else {
        _go(const LoginScreen());
      }
    }
  }

  void _routeByRole(String role) {
    if (role == 'citizen') {
      _go(const CitizenMainWrapper());
    } else if (role == 'hks' || role == 'hks_worker') {
      _go(const WorkerMainWrapper());
    } else if (role == 'panchayath') {
      _go(const PanchayathHomeScreen());
    } else if (role == 'admin') {
      _go(const AdminHomeScreen());
    } else {
      _go(const LoginScreen());
    }
  }

  void _go(Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
