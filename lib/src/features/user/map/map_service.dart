// map_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapService {
  final SupabaseClient _supabaseClient;

  MapService(this._supabaseClient);

  // Helper function to safely parse coordinates
  double _parseCoordinate(dynamic value, {double defaultValue = 0.0}) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    // If value is null or not a num/String, return default
    return defaultValue;
  }

  Future<List<Map<String, dynamic>>> fetchStations() async {
    try {
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from('charging_stations').select();
      
      return response.map((station) {
        final newStation = Map<String, dynamic>.from(station);
        // Use the helper to parse latitude and longitude safely
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
}
