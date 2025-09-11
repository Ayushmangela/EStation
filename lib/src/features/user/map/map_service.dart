import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchStations() async {
    try {
      final response = await _client
          .from('charging_stations')
          .select('station_id, name, latitude, longitude, address');

      print("Supabase response: $response"); // debug

      if (response.isEmpty) {
        print("No stations found!");
        return [];
      }

      return response.map((station) {
        return {
          "station_id": station['station_id'],
          "name": station['name'],
          "address": station['address'],
          "position": LatLng(
            (station['latitude'] as num).toDouble(),
            (station['longitude'] as num).toDouble(),
          ),
        };
      }).toList();
    } catch (e) {
      print("Error fetching stations: $e");
      return [];
    }
  }
}
