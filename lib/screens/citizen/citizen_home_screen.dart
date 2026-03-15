import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../location_picker_screen.dart';
import '../../illegal_dumping_screen.dart';
import '../../citizen_complaint_history_screen.dart';
import '../../create_complaint_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  String _userName = 'User';
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  bool _isManualEntry = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSavedLocation();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('houses').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['locationType'] == 'manual') {
          setState(() {
            _latController.text = data['latitude'].toString();
            _lngController.text = data['longitude'].toString();
            _isManualEntry = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved house location: $e');
    }
  }

  Future<void> _saveManualLocation() async {
    final latStr = _latController.text.trim();
    final lngStr = _lngController.text.trim();

    if (latStr.isEmpty || lngStr.isEmpty) {
      _showError('Please enter both latitude and longitude');
      return;
    }

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);

    if (lat == null || lat < -90 || lat > 90) {
      _showError('Latitude must be between -90 and 90');
      return;
    }

    if (lng == null || lng < -180 || lng > 180) {
      _showError('Longitude must be between -180 and 180');
      return;
    }

    setState(() => _isLoadingLocation = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('houses').doc(user.uid).set({
          'latitude': lat,
          'longitude': lng,
          'locationType': 'manual',
          'citizenId': user.uid,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('House location saved successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error saving location: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritham'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Navigate to notifications screen if needed
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.mintGreen, Colors.white],
            stops: [0.3, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Welcome to Haritham",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.harithamGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("🌱", style: TextStyle(fontSize: 24)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Logged in as $_userName",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textBlack.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daily Status Card
              HarithamCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.harithamGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.eco,
                        color: AppTheme.harithamGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "Collection scheduled for 10:00 AM",
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                "Quick Actions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),

              // HOUSE LOCATION SECTION
              HarithamCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.house, color: AppTheme.harithamGreen),
                        const SizedBox(width: 8),
                        const Text(
                          "House Location",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() => _isManualEntry = !_isManualEntry),
                          icon: Icon(_isManualEntry ? Icons.map : Icons.edit_location_alt),
                          label: Text(_isManualEntry ? "Use Map Picker" : "Set Location Manually"),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.harithamGreen),
                        ),
                      ],
                    ),
                    const Divider(),

                    // COORDINATE DISPLAY
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('houses').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        double? lat;
                        double? lng;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          lat = data['latitude'];
                          lng = data['longitude'];
                        }

                        if (lat != null && lng != null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Latitude: ${lat.toStringAsFixed(6)}",
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          "Longitude: ${lng.toStringAsFixed(6)}",
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (lat == null || lng == null) {
                                          _showError("House location not available.");
                                          return;
                                        }
                                        final url = "https://www.google.com/maps/search/?api=1&query=${lat},${lng}";
                                        launchUrl(
                                          Uri.parse(url),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                      icon: const Icon(Icons.map, size: 18),
                                      label: const Text("View on Map"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.harithamGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                              ],
                            ),
                          );
                        } else {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                "No location set for this house.",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    if (!_isManualEntry)
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "Use the map picker to point your house location accurately.",
                              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            HarithamButton(
                              label: "Pick From Map",
                              icon: Icons.my_location,
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                final LatLng? pickedLocation = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LocationPickerScreen(),
                                  ),
                                );

                                if (pickedLocation != null) {
                                  setState(() => _isLoadingLocation = true);
                                  try {
                                    await FirebaseFirestore.instance.collection('houses').doc(user.uid).set({
                                      'latitude': pickedLocation.latitude,
                                      'longitude': pickedLocation.longitude,
                                      'locationType': 'map',
                                      'citizenId': user.uid,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });

                                    // Also update profile legacy field
                                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                      'houseLocation': {
                                        'latitude': pickedLocation.latitude,
                                        'longitude': pickedLocation.longitude,
                                      },
                                    });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('House location updated successfully!')),
                                      );
                                    }
                                  } catch (e) {
                                    _showError('Error updating location: $e');
                                  } finally {
                                    if (mounted) setState(() => _isLoadingLocation = false);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          const Text(
                            "Enter the GPS coordinates manually for your house.",
                            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: HarithamTextField(
                                  label: "Latitude",
                                  prefixIcon: Icons.location_on,
                                  controller: _latController,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: HarithamTextField(
                                  label: "Longitude",
                                  prefixIcon: Icons.location_searching,
                                  controller: _lngController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: HarithamButton(
                              label: "Save Location",
                              icon: Icons.save,
                              onPressed: _isLoadingLocation ? null : _saveManualLocation,
                            ),
                          ),
                          if (_isLoadingLocation)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                "Quick Actions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildActionCard(
                    context,
                    Icons.report_problem_outlined,
                    "Illegal\nDumping",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IllegalDumpingScreen(),
                      ),
                    ),
                  ),
                  _buildActionCard(
                    context,
                    Icons.history_edu_outlined,
                    "Complaint\nHistory",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CitizenComplaintHistoryScreen(),
                      ),
                    ),
                  ),
                  _buildActionCard(
                    context,
                    Icons.error_outline,
                    "Report\nIssue",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateComplaintScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return HarithamCard(
      onTap: onTap,
      color: AppTheme.harithamGreen,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
