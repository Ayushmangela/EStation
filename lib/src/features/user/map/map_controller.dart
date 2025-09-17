//map_controller.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_service.dart';

typedef StationTapCallback = void Function(Map<String, dynamic> station);

class MapController {
  final MapService _mapService = MapService();
  final Set<Marker> _markers = {};
  final List<Map<String, dynamic>> _stations = [];

  Set<Marker> get markers => _markers;
  List<Map<String, dynamic>> get stations => _stations;

  Future<void> loadStations(StationTapCallback onStationTapped) async {
    debugPrint("[MapController] loadStations STARTED"); // ADDED THIS
    final fetchedStations = await _mapService.fetchStations();

    _markers.clear();
    _stations.clear();

    for (var stationData in fetchedStations) {
      final station = Map<String, dynamic>.from(stationData);
      _stations.add(station);

      _markers.add(
        Marker(
          markerId: MarkerId(station['station_id'].toString()),
          position: station['position'],
          infoWindow: InfoWindow(
            title: station['name'],
            snippet: station['address'],
          ),
          onTap: () => onStationTapped(station),
        ),
      );
    }

    debugPrint("Stations loaded: ${_stations.length}");
    debugPrint("Markers loaded: ${_markers.length}");
  }
}
