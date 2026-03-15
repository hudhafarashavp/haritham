import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'models/route_model.dart';
import 'services/route_service.dart';
import 'services/firestore_service.dart';
import 'services/user_service.dart';
import 'location_picker_screen.dart';

class RouteCreationScreen extends StatefulWidget {
  const RouteCreationScreen({super.key});

  @override
  State<RouteCreationScreen> createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final RouteService _routeService = RouteService();
  final UserService _userService = UserService();

  // Route Details
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Route 1';
  LatLng? _startLocation;
  LatLng? _endLocation;
  String _startAddress = '';
  String _endAddress = '';

  // Stops
  final List<Map<String, dynamic>> _stops = [];

  // Worker Assignment
  List<Map<String, dynamic>> _availableWorkers = [];
  Map<String, dynamic>? _selectedWorker;
  bool _isLoadingWorkers = true;

  // Map Preview
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Calculations
  double _estimatedDistance = 0.0;
  String _estimatedTime = '0 mins';
  String _currentPanchayathId = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await _firestoreService.getUserProfile(user.uid);
        if (profile != null) {
          setState(() {
            // Use panchayathId if exists, otherwise use uid as fallback (e.g. for pure panchayath accounts)
            _currentPanchayathId =
                profile['panchayathId'] ?? profile['uid'] ?? user.uid;
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        print("Error fetching profile: $e");
        setState(() => _isLoadingProfile = false);
      }
    } else {
      setState(() => _isLoadingProfile = false);
    }
    _fetchWorkers();
  }

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _fetchWorkers() async {
    try {
      final workers = await _userService.getWorkers();
      setState(() {
        _availableWorkers = workers;
        _isLoadingWorkers = false;
      });
    } catch (e) {
      setState(() => _isLoadingWorkers = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching workers: $e')));
    }
  }

  void _addStop() {
    setState(() {
      _stops.add({
        'name': '',
        'location': null,
        'controller': TextEditingController(),
      });
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      _updateMapAndCalculations();
    });
  }

  Future<void> _pickLocation(bool isStart, {int? stopIndex}) async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null) {
      setState(() {
        if (stopIndex != null) {
          _stops[stopIndex]['location'] = result;
          _stops[stopIndex]['controller'].text =
              '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
        } else if (isStart) {
          _startLocation = result;
          _startAddress =
              '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
        } else {
          _endLocation = result;
          _endAddress =
              '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
        }
      });
      _updateMapAndCalculations();
    }
  }

  void _updateMapAndCalculations() {
    _markers.clear();
    _polylines.clear();
    List<LatLng> points = [];

    if (_startLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _startLocation!,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
      points.add(_startLocation!);
    }

    for (int i = 0; i < _stops.length; i++) {
      if (_stops[i]['location'] != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: _stops[i]['location'],
            infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
        points.add(_stops[i]['location']);
      }
    }

    if (_endLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _endLocation!,
          infoWindow: const InfoWindow(title: 'End'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      points.add(_endLocation!);
    }

    if (points.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.green,
          width: 5,
        ),
      );

      // Calculate simple straight-line distance (Haversine approximation)
      double totalDistance = 0;
      for (int i = 0; i < points.length - 1; i++) {
        totalDistance += _calculateDistance(points[i], points[i + 1]);
      }

      setState(() {
        _estimatedDistance = totalDistance;
        // Assume average speed of 20 km/h for waste collection
        int minutes = ((totalDistance / 20) * 60).round();
        _estimatedTime = '$minutes mins';
      });

      // Zoom map to fit all markers
      if (_mapController != null) {
        _zoomToFit(points);
      }
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double r = 6371; // Earth radius in km
    double dLat = _degToRad(p2.latitude - p1.latitude);
    double dLon = _degToRad(p2.longitude - p1.longitude);
    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) *
            math.cos(_degToRad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  void _zoomToFit(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end locations')),
      );
      return;
    }

    setState(() => _isLoadingWorkers = true);

    try {
      final route = RouteModel(
        routeId: '', // Will be generated in service
        panchayathId: _currentPanchayathId,
        routeName: _nameController.text,
        routeType: _selectedType,
        workerId: _selectedWorker?['uid'],
        assignedWorkerName: _selectedWorker?['name'],
        startStop: _startAddress,
        endStop: _endAddress,
        intermediateStops: _stops
            .map((s) => s['controller'].text as String)
            .toList(),
        routeDate: DateTime.now(),
        startTime: '08:00',
        stops: [
          RouteStop(
            stopName: 'Start',
            latitude: _startLocation!.latitude,
            longitude: _startLocation!.longitude,
          ),
          ..._stops.map(
            (s) => RouteStop(
              stopName: 'Stop',
              latitude: s['location']?.latitude,
              longitude: s['location']?.longitude,
            ),
          ),
          RouteStop(
            stopName: 'End',
            latitude: _endLocation!.latitude,
            longitude: _endLocation!.longitude,
          ),
        ],
        totalDistance: _estimatedDistance,
        estimatedTime: _estimatedTime,
        status: 'Scheduled',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _routeService.createRoute(route);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWorkers = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving route: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Creation'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _isLoadingProfile
                ? [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ]
                : [
                    _buildSectionHeader('SECTION 1 — ROUTE DETAILS'),
                    _buildRouteDetailsCard(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('SECTION 2 — STOPS MANAGEMENT'),
                    _buildStopsCard(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('SECTION 3 — WORKER ASSIGNMENT'),
                    _buildWorkerAssignmentCard(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('SECTION 4 — MAP PREVIEW'),
                    _buildMapPreviewCard(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('SECTION 5 — ROUTE INFORMATION'),
                    _buildRouteInfoCard(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRouteDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Route Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.route),
              ),
              validator: (v) => v!.isEmpty ? 'Enter route name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Route Type',
                border: OutlineInputBorder(),
              ),
              items: [
                'Route 1',
                'Route 2',
                'Route 3',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            _buildLocationInput(
              label: 'Start Location',
              value: _startAddress,
              onTap: () => _pickLocation(true),
            ),
            const SizedBox(height: 16),
            _buildLocationInput(
              label: 'End Location',
              value: _endAddress,
              onTap: () => _pickLocation(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Tap to pick on map',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: const Icon(Icons.map_outlined),
      ),
      controller: TextEditingController(text: value),
      validator: (v) => value.isEmpty ? 'Select $label' : null,
    );
  }

  Widget _buildStopsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ..._stops.asMap().entries.map((entry) {
            int idx = entry.key;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue.shade700,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stops[idx]['controller'],
                      readOnly: true,
                      onTap: () => _pickLocation(false, stopIndex: idx),
                      decoration: InputDecoration(
                        hintText: 'Add Stop Location',
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_location),
                          onPressed: () => _pickLocation(false, stopIndex: idx),
                          tooltip: 'Add Location',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _removeStop(idx),
                  ),
                ],
              ),
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('ADD STOP'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerAssignmentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoadingWorkers
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedWorker,
                decoration: const InputDecoration(
                  labelText: 'Assign Worker',
                  border: OutlineInputBorder(),
                ),
                items: _availableWorkers.map((w) {
                  return DropdownMenuItem(
                    value: w,
                    child: Row(
                      children: [
                        Text(w['name'] ?? 'Unknown'),
                        const SizedBox(width: 8),
                        Text(
                          '(ID: ${w['uid'].toString().substring(0, 5)})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedWorker = v),
                validator: (v) => v == null ? 'Assign a worker' : null,
              ),
      ),
    );
  }

  Widget _buildMapPreviewCard() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(10.5276, 76.2144),
            zoom: 12,
          ),
          onMapCreated: (c) => _mapController = c,
          markers: _markers,
          polylines: _polylines,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Card(
      color: Colors.green.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(
              Icons.straighten,
              'Distance',
              '${_estimatedDistance.toStringAsFixed(1)} km',
            ),
            _buildInfoItem(Icons.timer, 'ETA', _estimatedTime),
            _buildInfoItem(Icons.pin_drop, 'Stops', '${_stops.length + 2}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.green.shade700),
              foregroundColor: Colors.green.shade700,
            ),
            child: const Text('CANCEL'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoadingWorkers ? null : _saveRoute,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoadingWorkers
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('SAVE ROUTE'),
          ),
        ),
      ],
    );
  }
}
