import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/route_model.dart';

class AssignRouteMapScreen extends StatefulWidget {
  final List<RouteStop> initialStops;
  const AssignRouteMapScreen({super.key, this.initialStops = const []});

  @override
  State<AssignRouteMapScreen> createState() => _AssignRouteMapScreenState();
}

class _AssignRouteMapScreenState extends State<AssignRouteMapScreen> {
  final Set<Marker> _markers = {};
  final List<RouteStop> _selectedStops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedStops.addAll(widget.initialStops);
    _loadCitizens();
  }

  Future<void> _loadCitizens() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'citizen')
          .get();

      final List<Marker> markers = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final houseLocation = data['houseLocation'];
        if (houseLocation != null) {
          final lat = houseLocation['latitude'] as double;
          final lng = houseLocation['longitude'] as double;
          final name = data['name'] ?? data['username'] ?? 'Citizen';
          final email = data['email'] ?? '';

          final isSelected = _selectedStops.any((s) => s.stopName == name);

          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isSelected
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueRed,
              ),
              onTap: () => _toggleStop(name, lat, lng, doc.id, email),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers.addAll(markers);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading citizens: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleStop(
    String name,
    double lat,
    double lng,
    String id,
    String email,
  ) {
    setState(() {
      final index = _selectedStops.indexWhere((s) => s.stopName == name);
      if (index != -1) {
        _selectedStops.removeAt(index);
        _updateMarker(id, false);
      } else {
        _selectedStops.add(
          RouteStop(
            stopName: name,
            latitude: lat,
            longitude: lng,
            status: 'Pending',
            citizenId: id,
            citizenEmail: email,
          ),
        );
        _updateMarker(id, true);
      }
    });
  }

  void _updateMarker(String id, bool isSelected) {
    final marker = _markers.firstWhere((m) => m.markerId.value == id);
    _markers.remove(marker);
    _markers.add(
      marker.copyWith(
        iconParam: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Houses'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedStops.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedStops),
              child: const Text(
                'CONFIRM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(10.5276, 76.2144), // Kerala
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Selected: ${_selectedStops.length} houses\nTap markers to add/remove from route',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
