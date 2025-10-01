import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStationService {
  final SupabaseClient _supabase;

  AdminStationService(this._supabase);

  Future<Map<String, dynamic>> addStation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required bool hasBikeCharger,
    required bool hasCarCharger,
    required String status,
    String? carChargerCapacity, // New parameter
    String? bikeChargerCapacity, // New parameter
  }) async {
    try {
      final stationResponse = await _supabase.from('charging_stations').insert({
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'has_bike_charger': hasBikeCharger,
        'has_car_charger': hasCarCharger,
        'status': status,
      }).select().single(); // Use single() to get one record or throw

      final stationId = stationResponse['station_id'] as int;

      if (carChargerCapacity != null && carChargerCapacity.isNotEmpty) {
        await _supabase.from('station_charger_capacity').insert({
          'station_id': stationId,
          'vehicle_type': 'car',
          'capacity_value': carChargerCapacity,
        });
      }
      if (bikeChargerCapacity != null && bikeChargerCapacity.isNotEmpty) {
        await _supabase.from('station_charger_capacity').insert({
          'station_id': stationId,
          'vehicle_type': 'bike',
          'capacity_value': bikeChargerCapacity,
        });
      }

      return stationResponse;
    } catch (e) {
      print('Error adding station or capacities: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateStation({
    required int stationId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required bool hasBikeCharger,
    required bool hasCarCharger,
    required String status,
    String? carChargerCapacity, // New parameter
    String? bikeChargerCapacity, // New parameter
  }) async {
    try {
      final stationResponse = await _supabase
          .from('charging_stations')
          .update({
            'name': name,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'has_bike_charger': hasBikeCharger,
            'has_car_charger': hasCarCharger,
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('station_id', stationId)
          .select()
          .single(); // Use single()

      // Update car charger capacity
      await _supabase
          .from('station_charger_capacity')
          .delete()
          .eq('station_id', stationId)
          .eq('vehicle_type', 'car');
      if (carChargerCapacity != null && carChargerCapacity.isNotEmpty) {
        await _supabase.from('station_charger_capacity').insert({
          'station_id': stationId,
          'vehicle_type': 'car',
          'capacity_value': carChargerCapacity,
        });
      }

      // Update bike charger capacity
      await _supabase
          .from('station_charger_capacity')
          .delete()
          .eq('station_id', stationId)
          .eq('vehicle_type', 'bike');
      if (bikeChargerCapacity != null && bikeChargerCapacity.isNotEmpty) {
        await _supabase.from('station_charger_capacity').insert({
          'station_id': stationId,
          'vehicle_type': 'bike',
          'capacity_value': bikeChargerCapacity,
        });
      }
      
      return stationResponse;
    } catch (e) {
      print('Error updating station or capacities: $e');
      rethrow;
    }
  }

  Future<void> deleteStation({required int stationId}) async {
    try {
      // First, delete related capacities
      await _supabase
          .from('station_charger_capacity')
          .delete()
          .eq('station_id', stationId);

      // Then, delete the station itself
      await _supabase
          .from('charging_stations')
          .delete()
          .eq('station_id', stationId);
    } catch (e) {
      print('Error deleting station and/or capacities: $e');
      rethrow;
    }
  }
}
