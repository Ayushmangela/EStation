import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../../admin/station_management/manage_stations_view.dart'; // For Station model

class MapService {
  final SupabaseClient _supabaseClient;

  MapService(this._supabaseClient);

  double _parseCoordinate(dynamic value, {double defaultValue = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Future<List<Station>> fetchStations() async {
    debugPrint("[MapService.fetchStations] Attempting to fetch stations from DB...");
    try {
      final List<Map<String, dynamic>> stationMaps =
          await _supabaseClient.from('charging_stations').select();

      debugPrint("[MapService.fetchStations] Fetched ${stationMaps.length} raw station entries from 'charging_stations'.");

      if (stationMaps.isEmpty) {
        debugPrint("[MapService.fetchStations] No stations found in the database or query returned empty.");
        return [];
      }

      final List<Station> stations = [];
      for (final stationMap in stationMaps) {
        final stationId = stationMap['station_id'];
        debugPrint("[MapService.fetchStations] Processing station ID: $stationId, Data: $stationMap");
        String? carCapacity;
        String? bikeCapacity;

        try {
          final capacitiesResponse = await _supabaseClient
              .from('station_charger_capacity')
              .select('vehicle_type, capacity_value')
              .eq('station_id', stationId);
          
          debugPrint("[MapService.fetchStations] Fetched ${capacitiesResponse.length} capacity entries for station ID: $stationId");

          for (final capMap in (capacitiesResponse as List)) {
            final type = capMap['vehicle_type'] as String?;
            final value = capMap['capacity_value'] as String?;
            if (type == 'car') {
              carCapacity = value;
            } else if (type == 'bike') {
              bikeCapacity = value;
            }
          }
          debugPrint("[MapService.fetchStations] For station ID: $stationId, CarCapacity: $carCapacity, BikeCapacity: $bikeCapacity");

          // Attempt to create Station object
          final station = Station.fromMap(stationMap, carCapacity: carCapacity, bikeCapacity: bikeCapacity);
          stations.add(station);
          debugPrint("[MapService.fetchStations] Successfully created Station object for ID: $stationId");

        } catch (e) {
          debugPrint("[MapService.fetchStations] Error processing capacities or creating Station object for station ID: $stationId. Error: $e. Raw stationMap: $stationMap");
          // Optionally, decide if a station should be added even if capacities fail, or skip it.
          // For now, if Station.fromMap or capacity fetching fails for one station, it's logged and skipped.
          // The main try-catch will catch broader errors.
        }
      }
      debugPrint("[MapService.fetchStations] Successfully processed ${stations.length} stations out of ${stationMaps.length}.");
      return stations;
    } catch (e) {
      debugPrint("[MapService.fetchStations] CRITICAL ERROR fetching or processing stations: $e");
      return []; // Return empty list on critical error
    }
  }

  Future<List<Map<String, dynamic>>> fetchStationsWithDistance() async {
    debugPrint("[MapService.fetchStationsWithDistance] Calling fetchStations...");
    try {
      final List<Station> stations = await fetchStations();
      debugPrint("[MapService.fetchStationsWithDistance] fetchStations returned ${stations.length} stations.");

      if (stations.isEmpty) {
        debugPrint("[MapService.fetchStationsWithDistance] No stations to calculate distance for.");
        return [];
      }

      final Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint("[MapService.fetchStationsWithDistance] Got user position: $userPosition");

      final List<Map<String, dynamic>> stationsWithDistance = stations.map((station) {
        final double distance = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          station.latitude,
          station.longitude,
        ) / 1000; // km
        // debugPrint("[MapService.fetchStationsWithDistance] Station ${station.stationId}: distance ${distance.toStringAsFixed(2)} km");
        return {'station': station, 'distance': distance};
      }).toList();
      
      // Sort by distance
      stationsWithDistance.sort((a, b) {
        final distA = a['distance'] as double? ?? double.infinity;
        final distB = b['distance'] as double? ?? double.infinity;
        return distA.compareTo(distB);
      });

      debugPrint("[MapService.fetchStationsWithDistance] Returning ${stationsWithDistance.length} stations with distance.");
      return stationsWithDistance;
    } catch (e) {
      debugPrint("[MapService.fetchStationsWithDistance] CRITICAL ERROR fetching stations with distance: $e");
      return [];
    }
  }
}
