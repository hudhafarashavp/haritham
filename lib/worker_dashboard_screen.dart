import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class WorkerDashboardScreen extends StatefulWidget {
  final String workerEmail;

  const WorkerDashboardScreen({super.key, required this.workerEmail});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _locationEnabled = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
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
          if (mounted) {
            setState(() {
              _locationEnabled = data['locationEnabled'] ?? false;
            });
          }
          if (_locationEnabled) {
            _startTracking();
          }
        }
      } catch (e) {
        debugPrint('Error loading dashboard location settings: $e');
      }
    }
  }

  Future<void> _toggleLocation(bool value) async {
    if (value) {
      bool permissionGranted = await _handleLocationPermission();
      if (permissionGranted) {
        await _updateFirestoreStatus(true);
        _startTracking();
      } else {
        if (mounted) setState(() => _locationEnabled = false);
      }
    } else {
      await _updateFirestoreStatus(false);
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
      _updateLocationInFirestore(position);
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _updateFirestoreStatus(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).update({
        'locationEnabled': enabled,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: widget.workerEmail)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('User profile not found'),
                    ),
                  );
                }

                final userData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(userData),
                      const SizedBox(height: 12),
                      // FORCEFUL LOCATION TRACKING UI
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.green),
                          title: const Text("Location Tracking"),
                          subtitle: const Text("Enable GPS tracking"),
                          trailing: Switch(
                            value: _locationEnabled,
                            onChanged: (value) {
                              setState(() {
                                _locationEnabled = value;
                              });
                              _toggleLocation(value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Assigned Route',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRouteCard(userData),
                      const SizedBox(height: 24),
                      _buildPerformanceSection(),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHistoryList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Haritham Worker',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
          ),
          child: Opacity(
            opacity: 0.1,
            child: Icon(Icons.eco, size: 200, color: Colors.white),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(Map<String, dynamic> userData) {
    final name = userData['name'] ?? userData['username'] ?? 'Worker';
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> userData) {
    final routeId = userData['assignedRouteId'];
    final routeNumber = userData['assignedRouteNumber'];
    final startStop = userData['assignedStartStop'];
    final endStop = userData['assignedEndStop'];
    final intermediateStops = List<String>.from(
      userData['assignedIntermediateStops'] ?? [],
    );

    if (routeId == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.green.shade100, width: 2),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route_outlined,
                size: 64,
                color: Colors.green.shade200,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Route Assigned',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contact your administrator to get a route assignment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.green.shade800, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          routeNumber ?? 'Assigned Route',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.map_outlined, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStopRow(
                    Icons.radio_button_checked,
                    'START',
                    startStop ?? 'Not set',
                    isFirst: true,
                  ),
                  if (intermediateStops.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: 2,
                        height: 24,
                        color: Colors.white30,
                      ),
                    ),
                  if (intermediateStops.isNotEmpty)
                    _buildStopRow(
                      Icons.trip_origin,
                      'STOPS',
                      intermediateStops.join(', '),
                      isIntermediate: true,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      width: 2,
                      height: 24,
                      color: Colors.white30,
                    ),
                  ),
                  _buildStopRow(
                    Icons.location_on,
                    'END',
                    endStop ?? 'Not set',
                    isLast: true,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation),
                    label: const Text('START NAVIGATION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopRow(
    IconData icon,
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
    bool isIntermediate = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isIntermediate ? 18 : 24,
          color: isFirst
              ? Colors.blue.shade200
              : (isLast ? Colors.red.shade200 : Colors.white70),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Impact',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Houses',
                '45',
                Icons.home_work,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Plastic',
                '12kg',
                Icons.recycling,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Waste',
                '28kg',
                Icons.delete_sweep,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .where(
                      'workerId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .where('paymentStatus', isEqualTo: 'completed')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData
                      ? snapshot.data!.docs.length
                      : 0;
                  return _buildStatTile(
                    'Payments',
                    '$count',
                    Icons.payments,
                    Colors.purple,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: Icon(Icons.check_circle, color: Colors.green.shade600),
            ),
            title: Text('Route ${index + 1} Completed'),
            subtitle: Text(
              DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.now().subtract(Duration(days: index + 1))),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}
