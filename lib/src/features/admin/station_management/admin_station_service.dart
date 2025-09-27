import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStationService {
  final SupabaseClient _supabase;

  AdminStationService(this._supabase);

  Future<Map<String, dynamic>> addStation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    // required String? operator, // Removed operator
    required bool hasBikeCharger,
    required bool hasCarCharger,
    required String status,
  }) async {
    try {
      final response = await _supabase.from('charging_stations').insert({
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        // 'operator': operator, // Removed operator
        'has_bike_charger': hasBikeCharger,
        'has_car_charger': hasCarCharger,
        'status': status,
      }).select();

      if (response.isEmpty) {
        throw Exception('Failed to add station, no data returned.');
      }
      return response[0];
    } catch (e) {
      print('Error adding station: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateStation({
    required int stationId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    // String? operator, // Removed operator
    required bool hasBikeCharger,
    required bool hasCarCharger,
    required String status,
  }) async {
    try {
      final response = await _supabase
          .from('charging_stations')
          .update({
            'name': name,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            // 'operator': operator, // Removed operator
            'has_bike_charger': hasBikeCharger,
            'has_car_charger': hasCarCharger,
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('station_id', stationId)
          .select();

      if (response.isEmpty) {
        throw Exception('Failed to update station, no data returned or station not found.');
      }
      return response[0];
    } catch (e) {
      print('Error updating station: $e');
      rethrow;
    }
  }

  Future<void> deleteStation({required int stationId}) async {
    try {
      await _supabase
          .from('charging_stations')
          .delete()
          .eq('station_id', stationId);
    } catch (e) {
      print('Error deleting station: $e');
      rethrow;
    }
  }
}
