import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStationService {
  final SupabaseClient _supabase;

  AdminStationService(this._supabase);

  Future<Map<String, dynamic>> addStation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required String? operator,
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
        'operator': operator,
        'has_bike_charger': hasBikeCharger,
        'has_car_charger': hasCarCharger,
        'status': status,
      }).select();

      return response[0];
    } catch (e) {
      print('Error adding station: $e');
      rethrow;
    }
  }
}
