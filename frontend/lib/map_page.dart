import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  StreamSubscription<Position>? _positionStream;
  LatLng _currentPos = const LatLng(7.8731, 80.7718); // Default Sri Lanka

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndTrack();
  }

  // 1. ROBUST PERMISSION CHECKER
  Future<void> _checkPermissionsAndTrack() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; // User needs to turn on GPS

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    // 2. START TRACKING
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      LatLng newLatLng = LatLng(position.latitude, position.longitude);
      setState(() => _currentPos = newLatLng);
      
      // Follow user with camera
      _controller?.animateCamera(CameraUpdate.newLatLng(newLatLng));
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure the map fills the screen correctly
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPos, zoom: 14),
            onMapCreated: (c) => _controller = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId("current_loc"),
                position: _currentPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            },
          ),
          
          // Floating Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}