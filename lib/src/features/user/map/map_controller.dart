// map_controller.dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Added import
import 'map_service.dart';

typedef StationTapCallback = void Function(Map<String, dynamic> station);

class MapController {
  final MapService _mapService;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _stations = [];
  BitmapDescriptor? _stationIcon; // Custom icon

  MapController(this._mapService);

  Set<Marker> get markers => _markers;
  List<Map<String, dynamic>> get stations => _stations;

  // User's provided distance calculation function
  double calculateDistanceKm(
      double userLat, double userLng, double stationLat, double stationLng) {
    // distanceBetween returns meters
    double distanceMeters = Geolocator.distanceBetween(
        userLat, userLng, stationLat, stationLng);
    double distanceKm = distanceMeters / 1000; // convert to km
    return distanceKm;
  }

  Future<BitmapDescriptor> _resizeAndLoadMarker(
      String assetPath, int width, int height) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;

    final ByteData? byteData =
    await resizedImage.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadMarkerIcon() async {
    try {
      _stationIcon = await _resizeAndLoadMarker(
        'assets/StationMap.png',
        110, // width
        110, // height
      );
      debugPrint("[MapController] Custom marker icon loaded");
    } catch (e) {
      debugPrint("[MapController] Error loading marker icon: $e");
      _stationIcon = BitmapDescriptor.defaultMarker;
    }
  }

  // Modified to accept userPosition
  Future<bool> loadStations(LatLng? userPosition, StationTapCallback onStationTapped) async {
    debugPrint("[MapController] loadStations STARTED");

    if (_stationIcon == null) {
      await _loadMarkerIcon();
    }

    final fetchedStations = await _mapService.fetchStations();

    _markers.clear();
    _stations = List<Map<String, dynamic>>.from(fetchedStations);

    for (var stationData in _stations) {
      final String stationIdString =
          stationData['station_id']?.toString() ??
              'station_${DateTime.now().millisecondsSinceEpoch}_${_markers.length}';
      
      final LatLng stationLatLng = stationData['position'] as LatLng? ?? const LatLng(0, 0);
      double? distanceKm;

      if (userPosition != null) {
        distanceKm = calculateDistanceKm(
            userPosition.latitude, userPosition.longitude, stationLatLng.latitude, stationLatLng.longitude);
        stationData['distance'] = distanceKm; // Save to station map for later use in StationCard
      }

      _markers.add(
        Marker(
          markerId: MarkerId(stationIdString),
          position: stationLatLng,
          infoWindow: InfoWindow(
            title: stationData['name'] as String?,
            snippet: distanceKm != null
                ? "${distanceKm.toStringAsFixed(2)} km away"
                : stationData['address'] as String?, // Fallback to address if distance not available
          ),
          icon: _stationIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () => onStationTapped(stationData),
        ),
      );
    }

    // Sort stations by distance if userPosition is available
    if (userPosition != null) {
      _stations.sort((a, b) {
        final distA = a['distance'] as double?;
        final distB = b['distance'] as double?;
        if (distA == null && distB == null) return 0;
        if (distA == null) return 1; // stations with no distance go last
        if (distB == null) return -1; // stations with no distance go last
        return distA.compareTo(distB);
      });
    }
    
    debugPrint("Stations loaded: ${_stations.length}");
    debugPrint("Markers loaded: ${_markers.length}");
    return true;
  }
}
