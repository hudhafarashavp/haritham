import 'dart:async';
import 'package:flutter/material.dart';
import 'worker_settings_screen.dart';
import '../edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_task_history_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  String _name = 'Loading...';
  String _id = '';
  String _phone = '';
  String _workerIdCustom = '';
  
  // Location Tracking State
  bool _locationEnabled = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLocationSettings();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadLocationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('workers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _locationEnabled = data['locationEnabled'] ?? false;
          });
          if (_locationEnabled) {
            _startTracking();
          }
        }
      } catch (e) {
        debugPrint('Error loading location profile settings: $e');
      }
    }
  }

  Future<void> _toggleLocation(bool value) async {
    if (value) {
      bool permissionGranted = await _handleLocationPermission();
      if (permissionGranted) {
        await _updateLocationStatus(true);
        _startTracking();
      } else {
        setState(() => _locationEnabled = false);
      }
    } else {
      await _updateLocationStatus(false);
      _stopTracking();
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return false;
      }
    }
    return true;
  }

  void _startTracking() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('workers').doc(user.uid).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _updateLocationStatus(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).update({
        'locationEnabled': enabled,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? prefs.getString('userName') ?? 'Worker';
          _id = user.uid.substring(0, 8);
          _phone = data['phone'] ?? "No phone set";
          _workerIdCustom = data['workerId'] ?? data['worker_id'] ?? _id;
        });
      } else {
        setState(() {
          _name = prefs.getString('userName') ?? 'Worker';
          _id = user.uid.substring(0, 8);
          _phone = "No phone set";
          _workerIdCustom = _id;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.softGrey,
                    child: Icon(
                      Icons.engineering_outlined,
                      size: 40,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(width: 40),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bio Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "ID: #$_workerIdCustom",
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(_phone),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Profile Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Row(
                children: [
                  Expanded(
                    child: HarithamButton(
                      label: "Edit Profile",
                      isPrimary: false,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen(role: 'hks_worker')),
                        );
                        if (result == true) _loadProfile();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Location Tracking Toggle (Maximum Visibility)
            _ProfileLink(
              icon: Icons.location_on,
              label: "Location Tracking",
              color: Colors.green,
              trailing: Switch(
                value: _locationEnabled,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() => _locationEnabled = value);
                  _toggleLocation(value);
                },
              ),
              onTap: () {},
            ),
            const Divider(),
            // Quick Links
            _ProfileLink(
              icon: Icons.history,
              label: "Task History",
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkerTaskHistoryScreen(workerId: user.uid),
                    ),
                  );
                }
              },
            ),
            _ProfileLink(
              icon: Icons.settings_outlined,
              label: "Settings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkerSettingsScreen(),
                  ),
                );
              },
            ),
            _ProfileLink(
              icon: Icons.logout,
              label: "Logout",
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                }
              },
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

// Redundant _StatItem removed

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textBlack),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppTheme.textBlack,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: trailing == null ? onTap : null,
    );
  }
}
