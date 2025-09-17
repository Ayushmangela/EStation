import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

import 'map_controller.dart';
import 'station_card.dart';

class UserMapView extends StatefulWidget {
  const UserMapView({super.key});

  @override
  State<UserMapView> createState() => _UserMapViewState();
}

class _UserMapViewState extends State<UserMapView> {
  GoogleMapController? _mapController;
  final MapController _mapControllerHelper = MapController();

  LatLng? _currentPosition;
  String? _mapStyle;
  bool _isLoading = true;
  bool _showListView = false;
  Map<String, dynamic>? _selectedStation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    debugPrint("[UserMapView] _initializeMap STARTED"); // ADDED THIS
    await _getCurrentLocation();

    if (mounted) setState(() => _isLoading = false);

    _loadMapStyle();

    debugPrint("[UserMapView] CALLING _mapControllerHelper.loadStations()"); // ADDED THIS
    _mapControllerHelper.loadStations((station) {
      if (mounted) {
        setState(() {
          _selectedStation = station;
          _showListView = false;
        });
        _animateToStation(station);
      }
    }).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _animateToStation(Map<String, dynamic> station) async {
    // Added debug prints from previous step - keeping them
    debugPrint("Attempting to animate to station: ${station['name']}");
    debugPrint("Raw station data for animation: $station");
    final LatLng? stationPosition = station['position'] as LatLng?;
    debugPrint("Parsed LatLng for station: $stationPosition");

    try {
      if (_mapController != null && stationPosition != null) {
        debugPrint("Animating to $stationPosition for station: ${station['name']}");
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: stationPosition, zoom: 17),
          ),
        );
        debugPrint("Successfully animated to station: ${station['name']}");
      } else {
        debugPrint("Animation skipped: _mapController is null or stationPosition is null for ${station['name']}");
      }
    } catch (e) {
      debugPrint("Error animating to station: $e");
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.txt');
    } catch (e) {
      debugPrint("Error loading map style: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied.");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission permanently denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(19.0760, 72.8777),
              zoom: _currentPosition != null ? 16 : 12,
            ),
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              debugPrint("Map controller created");

              if (_mapStyle != null) {
                try {
                  await controller.setMapStyle(_mapStyle);
                  debugPrint("Map style applied");
                } catch (e) {
                  debugPrint("Error setting map style: $e");
                }
              }
            },
            markers: _mapControllerHelper.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onTap: (_) {
              if (mounted) setState(() => _selectedStation = null);
            },
          ),
          if (_showListView)
            Container(
              color: Colors.white,
              child: _buildListView(),
            ),
          if (!_showListView && _selectedStation != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: StationCard(
                name: _selectedStation!['name'] ?? "Charging Station",
                address: _selectedStation!['address'] ?? "No address",
                onViewPressed: () {
                  if (mounted) setState(() => _selectedStation = null);
                },
                onBookPressed: () {
                  debugPrint("Book tapped for ${_selectedStation!['name']}");
                },
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildSearchRow(),
                  const SizedBox(height: 12),
                  _buildToggleButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final stations = _mapControllerHelper.stations;
    if (stations.isEmpty) {
      return const Center(
        child: Text("Loading stations or no stations available..."),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return StationCard(
          name: station['name'] ?? 'Charging Station',
          address: station['address'] ?? 'No address',
          onViewPressed: () {
            debugPrint("View station tapped: ${station['name']}");
            debugPrint("Station position: ${station['position']}");

            if (mounted) {
              setState(() {
                _selectedStation = station;
                _showListView = false;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _animateToStation(station);
              });
            }
          },
          onBookPressed: () {
            debugPrint("Book button tapped for ${station['name']}");
          },
        );
      },
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                )
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search),
                hintText: "Search location",
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: !_showListView ? Colors.green : Colors.white,
            foregroundColor: !_showListView ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (mounted) {
              setState(() => _showListView = false);
            }
          },
          child: const Text("Map view"),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _showListView ? Colors.green : Colors.white,
            foregroundColor: _showListView ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (mounted) {
              setState(() {
                _showListView = true;
                _selectedStation = null;
              });
            }
          },
          child: const Text("List view"),
        ),
      ],
    );
  }
}