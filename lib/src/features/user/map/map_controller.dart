// map_controller.dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_service.dart';
import '../../admin/station_management/manage_stations_view.dart'; // For Station model

// This callback will pass the map containing both the Station object and its distance
typedef StationTapCallback = void Function(Map<String, dynamic> stationDataMap);

class MapController {
  final MapService _mapService;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _stationsData = []; // Stores maps like {'station': Station, 'distance': double}
  BitmapDescriptor? _stationIcon;

  MapController(this._mapService);

  Set<Marker> get markers => _markers;
  List<Map<String, dynamic>> get stations => _stationsData;

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
    } catch (e) {
      _stationIcon = BitmapDescriptor.defaultMarker;
    }
  }

  Future<bool> loadStations(
      LatLng? userPosition, StationTapCallback onStationTapped) async {
    if (_stationIcon == null) {
      await _loadMarkerIcon();
    }

    _stationsData = await _mapService.fetchStationsWithDistance();
    _markers.clear();

    if (_stationsData.isEmpty) {
      return false;
    }

    for (var stationMapEntry in _stationsData) {
      final Station stationObject = stationMapEntry['station'] as Station;
      final double? distanceKm = stationMapEntry['distance'] as double?;

      final String stationIdString = stationObject.stationId.toString();
      final LatLng stationLatLng = LatLng(stationObject.latitude, stationObject.longitude);

      _markers.add(
        Marker(
          markerId: MarkerId(stationIdString),
          position: stationLatLng,
          infoWindow: InfoWindow(
            title: stationObject.name,
            snippet: distanceKm != null
                ? "${distanceKm.toStringAsFixed(1)} km away"
                : stationObject.address,
          ),
          icon: _stationIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () => onStationTapped(stationMapEntry),
        ),
      );
    }
    
    return true;
  }
}
