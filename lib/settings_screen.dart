import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool waste = true;
  bool complaint = true;
  bool loading = false;
  
  // Location variables
  bool _locationEnabled = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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
        debugPrint('Error loading location settings: $e');
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

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied.')),
        );
      }
      return false;
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

  // Load saved notification preferences
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');
    if (phone == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      setState(() {
        waste = data['notificationPref']?['waste'] ?? true;
        complaint = data['notificationPref']?['complaint'] ?? true;
      });
    }
  }

  // Save notification preferences
  Future<void> _save() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');
    if (phone == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'notificationPref': {
          'waste': waste,
          'complaint': complaint,
        }
      });
    }

    setState(() => loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
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
        title: const Text('Notification Settings'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // LOCATION TRACKING TOGGLE (Attempt 3)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text(
                "Location Tracking",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Enable worker GPS tracking"),
              trailing: Switch(
                activeColor: Colors.green,
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() => _locationEnabled = value);
                  _toggleLocation(value);
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text(
                'Waste Notifications',
                style: TextStyle(color: Colors.green),
              ),
              activeColor: Colors.green,
              value: waste,
              onChanged: (v) => setState(() => waste = v),
            ),

            SwitchListTile(
              title: const Text(
                'Complaint Notifications',
                style: TextStyle(color: Colors.green),
              ),
              activeColor: Colors.green,
              value: complaint,
              onChanged: (v) => setState(() => complaint = v),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 180,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: loading ? null : _save,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
