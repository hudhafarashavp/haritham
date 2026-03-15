import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const LocationPickerScreen({
    super.key,
    this.initialPosition = const LatLng(
      10.5276,
      76.2144,
    ), // Default to Kerala coordinates
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _pickedPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition.latitude != 0.0) {
      _pickedPosition = widget.initialPosition;
    }
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _pickedPosition = latLng;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_pickedPosition != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _pickedPosition),
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
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition.latitude != 0.0
                  ? widget.initialPosition
                  : const LatLng(10.5276, 76.2144),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (position) {
              setState(() {
                _pickedPosition = position;
              });
            },
            markers: _pickedPosition == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _pickedPosition!,
                    ),
                  },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.green),
            ),
          ),
          if (_pickedPosition != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Lat: ${_pickedPosition!.latitude.toStringAsFixed(6)}, Lng: ${_pickedPosition!.longitude.toStringAsFixed(6)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
