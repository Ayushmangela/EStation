import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

import 'map_controller.dart';

class UserMapView extends StatefulWidget {
  const UserMapView({super.key});

  @override
  State<UserMapView> createState() => _UserMapViewState();
}

class _UserMapViewState extends State<UserMapView> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final MapController _mapController = MapController();

  LatLng? _currentPosition;
  String? _mapStyle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadMapStyle();
    await _getCurrentLocation();
    await _mapController.loadStations();

    if (mounted) {
      setState(() {}); // rebuild map with markers
      _isLoading = false;
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.txt');
    } catch (e) {
      print("Error loading map style: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _animateToCurrentLocation(GoogleMapController controller) {
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition ?? const LatLng(19.0760, 72.8777),
        zoom: 20,
      ),
      onMapCreated: (GoogleMapController controller) {
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
        if (_mapStyle != null) {
          controller.setMapStyle(_mapStyle);
        }
        _animateToCurrentLocation(controller);
      },
      markers: _mapController.markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: true,
    );
  }
}
