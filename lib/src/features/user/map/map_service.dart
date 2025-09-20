import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapService {
  final SupabaseClient _supabaseClient;

  MapService(this._supabaseClient);

  double _parseCoordinate(dynamic value, {double defaultValue = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Future<List<Map<String, dynamic>>> fetchStations() async {
    try {
      final List<Map<String, dynamic>> response =
      await _supabaseClient.from('charging_stations').select();

      return response.map((station) {
        final newStation = Map<String, dynamic>.from(station);
        final double latitude = _parseCoordinate(station['latitude']);
        final double longitude = _parseCoordinate(station['longitude']);
        newStation['position'] = LatLng(latitude, longitude);
        return newStation;
      }).toList();
    } catch (e) {
      print('Error fetching stations in MapService: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchStationsWithDistance() async {
    try {
      final stations = await fetchStations();
      final Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return stations.map((station) {
        final LatLng pos = station['position'];
        final double distance = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          pos.latitude,
          pos.longitude,
        ) / 1000; // km
        return {...station, 'distance': distance};
      }).toList();
    } catch (e) {
      print("Error fetching stations with distance: $e");
      return [];
    }
  }
}
