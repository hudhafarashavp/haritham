import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/app_theme.dart';
import '../../login_screen.dart';
import '../edit_profile_screen.dart';
import '../about_haritham_screen.dart';
import '../help_support_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth; 

class CitizenSettingsScreen extends StatefulWidget {
  const CitizenSettingsScreen({super.key});

  @override
  State<CitizenSettingsScreen> createState() => _CitizenSettingsScreenState();
}

class _CitizenSettingsScreenState extends State<CitizenSettingsScreen> {
  bool _locationEnabled = false;
  bool _notificationsEnabled = true;
  String? _role;
  bool _isLoading = true;
  String _language = 'English';
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = auth.FirebaseAuth.instance.currentUser;
    
    setState(() {
      _role = prefs.getString('role');
      _language = prefs.getString('language') ?? 'English';
    });

    if (user != null) {
      try {
        final collection = _role == 'citizen' ? 'users' : 'workers';
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _locationEnabled = data['locationEnabled'] ?? false;
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
            _language = data['language'] ?? _language;
          });
          if (_locationEnabled) {
            _startTracking();
          }
        }
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final collection = _role == 'citizen' ? 'users' : 'workers';
      await FirebaseFirestore.instance.collection(collection).doc(user.uid).update({
        'language': lang,
      });
    }
    setState(() => _language = lang);
  }

  Future<void> _toggleNotifications(bool value) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final collection = _role == 'citizen' ? 'users' : 'workers';
      await FirebaseFirestore.instance.collection(collection).doc(user.uid).update({
        'notificationsEnabled': value,
      });
      setState(() => _notificationsEnabled = value);
    }
  }

  Future<void> _changePassword() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to ${user.email}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _role = prefs.getString('role');
    });

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();
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
        debugPrint('Error loading citizen settings location: $e');
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
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
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

  @override
  Widget build(BuildContext context) {
    final isWorker = _role == 'hks_worker' || _role == 'hks';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        children: [
          _SettingSection(
            title: "Profile",
            items: [
              _SettingItem(
                icon: Icons.person_outline,
                label: "Edit Profile",
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(role: _role ?? 'citizen'),
                    ),
                  );
                  if (result == true) _loadAllSettings();
                },
              ),
            ],
          ),
          _SettingSection(
            title: "Preferences",
            items: [
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.textBlack),
                title: const Text("Language"),
                trailing: DropdownButton<String>(
                  value: _language,
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) _updateLanguage(newValue);
                  },
                  items: <String>['English']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none, color: AppTheme.textBlack),
                title: const Text("Notifications"),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (v) => _toggleNotifications(v),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text("Location Services"),
                subtitle: const Text("Store coordinates in Firestore"),
                trailing: Switch(
                  activeColor: Colors.green,
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() => _locationEnabled = value);
                    _toggleLocation(value);
                  },
                ),
              ),
            ],
          ),
          _SettingSection(
            title: "Security",
            items: [
              _SettingItem(
                icon: Icons.lock_outline,
                label: "Change Password",
                onTap: _changePassword,
              ),
            ],
          ),
          _SettingSection(
            title: "Support",
            items: [
              _SettingItem(
                icon: Icons.help_outline,
                label: "Help & Support",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                ),
              ),
              _SettingItem(
                icon: Icons.info_outline,
                label: "About Haritham",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutHarithamScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingItem(
            icon: Icons.logout,
            label: "Logout",
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await auth.FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
            color: Colors.red,
            showChevron: false,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool showChevron;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textBlack),
      title: Text(label, style: TextStyle(color: color ?? AppTheme.textBlack)),
      trailing: showChevron ? const Icon(Icons.chevron_right, size: 20) : null,
      onTap: onTap,
    );
  }
}
