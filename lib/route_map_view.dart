import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'models/route_model.dart';
import 'providers/route_provider.dart';
import 'dart:async';

class RouteMapView extends StatefulWidget {
  final RouteModel route;
  const RouteMapView({super.key, required this.route});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initMapData();
    _getCurrentLocation();
  }

  void _initMapData() {
    final stops = widget.route.stops;
    Set<Marker> markers = {};
    List<LatLng> polylinePoints = [];

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop.latitude == null || stop.longitude == null) continue;

      final pos = LatLng(stop.latitude!, stop.longitude!);
      polylinePoints.add(pos);

      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: pos,
          infoWindow: InfoWindow(
            title: stop.stopName,
            snippet: 'Status: ${stop.status}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            stop.status == 'Completed'
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          onTap: () {
            if (stop.status != 'Completed') {
              _showPickupDialog(i, stop);
            }
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue.withOpacity(0.6),
          width: 5,
        ),
      };
    });
  }

  void _showPickupDialog(int index, RouteStop stop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(stop.stopName),
        content: const Text('Mark this house as picked up?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStopStatus(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('PICKUP', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    });

    if (_currentPosition != null) {
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    }
  }

  Future<void> _updateStopStatus(int index) async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    final success = await routeProvider.updateStopStatus(
      widget.route.routeId,
      index,
      'Completed',
    );

    if (success && mounted) {
      setState(() {
        final markerId = MarkerId('stop_$index');
        final marker = _markers.firstWhere((m) => m.markerId == markerId);
        _markers.remove(marker);
        _markers.add(
          marker.copyWith(
            iconParam: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup marked as completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial camera position at first stop or current position
    LatLng initialPos = const LatLng(10.5276, 76.2144);
    if (widget.route.stops.isNotEmpty) {
      final firstStop = widget.route.stops.first;
      if (firstStop.latitude != null && firstStop.longitude != null) {
        initialPos = LatLng(firstStop.latitude!, firstStop.longitude!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
        onMapCreated: (GoogleMapController controller) =>
            _controller.complete(controller),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
