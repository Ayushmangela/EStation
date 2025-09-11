import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_service.dart';

class MapController {
  final MapService _mapService = MapService();
  final Set<Marker> _markers = {};

  Set<Marker> get markers => _markers;

  Future<void> loadStations() async {
    final stations = await _mapService.fetchStations();

    _markers.clear();

    for (var station in stations) {
      _markers.add(Marker(
        markerId: MarkerId(station['station_id'].toString()),
        position: station['position'],
        infoWindow: InfoWindow(
          title: station['name'],
          snippet: station['address'],
        ),
      ));
    }

    print("Markers loaded: ${_markers.length}");
  }
}
