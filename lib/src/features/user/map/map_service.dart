//map_service.dart

import 'package:flutter/material.dart'; // Added for debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchStations() async {
    debugPrint("[MapService] fetchStations STARTED"); // ADDED THIS
    try {
      final response = await _client
          .from('charging_stations')
          .select('station_id, name, latitude, longitude, address');

      // Existing print, changed to debugPrint for consistency
      debugPrint("Supabase response: $response"); 

      if (response.isEmpty) {
        debugPrint("No stations found!"); // Changed to debugPrint
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
      debugPrint("Error fetching stations: $e"); // Changed to debugPrint
      return [];
    }
  }
}
