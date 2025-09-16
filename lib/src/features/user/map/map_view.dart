import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

import 'map_controller.dart';
import 'station_card.dart'; // Ensure this is the updated StationCard

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
  bool _showMap = true;
  Map<String, dynamic>? _selectedStation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();

    if (mounted) setState(() => _isLoading = false);

    _loadMapStyle().then((_) async {
      if (mounted && _mapStyle != null) {
        final GoogleMapController controller = await _controllerCompleter.future;
        controller.setMapStyle(_mapStyle);
      }
    });

    _mapController.loadStations((station) {
      if (mounted) {
        setState(() {
          _selectedStation = station;
          _showMap = true;
        });
        _animateToStation(station);
      }
    }).then((_) {
      if (mounted) setState(() {}); // Refresh to show markers after loading
    });
  }

  Future<void> _animateToStation(Map<String, dynamic> station) async {
    final GoogleMapController controller = await _controllerCompleter.future;
    final LatLng? stationPosition = station['position'] as LatLng?;
    if (stationPosition != null) {
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: stationPosition, zoom: 17),
      ));
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
          Positioned.fill(
            child: _showMap
                ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                _currentPosition ?? const LatLng(19.0760, 72.8777),
                zoom: _currentPosition != null ? 16 : 12,
              ),
              onMapCreated: (controller) {
                if (!_controllerCompleter.isCompleted) {
                  _controllerCompleter.complete(controller);
                }
                if (_mapStyle != null) controller.setMapStyle(_mapStyle);
              },
              markers: _mapController.markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: true,
              onTap: (_) {
                if (mounted) setState(() => _selectedStation = null);
              },
            )
                : _buildListView(),
          ),
          if (_showMap && _selectedStation != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: StationCard(
                name: _selectedStation!['name'] ?? "Charging Station",
                address: _selectedStation!['address'] ?? "No address",
                // chargerType and capacity removed here
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
    final stations = _mapController.stations;
    if (stations.isEmpty) {
      return const Center(child: Text("Loading stations or no stations available..."));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return StationCard(
          name: station['name'] ?? 'Charging Station',
          address: station['address'] ?? 'No address',
          // chargerType and capacity removed here
          onViewPressed: () {
            if (mounted) {
              setState(() {
                _selectedStation = station;
                _showMap = true;
              });
            }
            _animateToStation(station);
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
            backgroundColor: _showMap ? Colors.green : Colors.white,
            foregroundColor: _showMap ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (mounted) setState(() => _showMap = true);
          },
          child: const Text("Map view"),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: !_showMap ? Colors.green : Colors.white,
            foregroundColor: !_showMap ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (mounted) {
              setState(() {
                _showMap = false;
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
