//map_controller.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_service.dart';

typedef StationTapCallback = void Function(Map<String, dynamic> station);

class MapController {
  final MapService _mapService; 
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _stations = []; 

  MapController(this._mapService);

  Set<Marker> get markers => _markers;
  List<Map<String, dynamic>> get stations => _stations; 

  Future<bool> loadStations(StationTapCallback onStationTapped) async {
    debugPrint("[MapController] loadStations STARTED");
    final fetchedStations = await _mapService.fetchStations();

    _markers.clear();
    _stations = List<Map<String, dynamic>>.from(fetchedStations);

    for (var stationData in _stations) { 
      final String stationIdString = stationData['station_id']?.toString() ?? 'station_${DateTime.now().millisecondsSinceEpoch}_${_markers.length}';
      _markers.add(
        Marker(
          markerId: MarkerId(stationIdString),
          // Ensure a non-null LatLng, defaulting if stationData['position'] is null or not a LatLng
          position: stationData['position'] as LatLng? ?? const LatLng(0, 0),
          infoWindow: InfoWindow(
            title: stationData['name'] as String?,
            snippet: stationData['address'] as String?,
          ),
          onTap: () => onStationTapped(stationData),
        ),
      );
    }
    debugPrint("Stations loaded: ${_stations.length}");
    debugPrint("Markers loaded: ${_markers.length}");
    return true; 
  }
}
