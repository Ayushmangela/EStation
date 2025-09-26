import 'package:supabase_flutter/supabase_flutter.dart';

class BookingService {
  final SupabaseClient _supabase;

  BookingService(this._supabase);

  Future<List<Map<String, dynamic>>> getBookedSlots({
    required int stationId,
    required String vehicleType,
    required DateTime date,
  }) async {
    try {
      final response = await _supabase
          .from('user_bookings')
          .select('start_time')
          .eq('station_id', stationId)
          .eq('vehicle_type', vehicleType)
          .eq('booking_date', '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching booked slots: $e');
      rethrow;
    }
  }

  Future<void> createBooking({
    required String userId,
    required int stationId,
    required String vehicleType,
    required DateTime bookingDate,
    required String startTime,
  }) async {
    try {
      await _supabase.from('user_bookings').insert({
        'user_id': userId,
        'station_id': stationId,
        'vehicle_type': vehicleType,
        'booking_date': '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}',
        'start_time': startTime,
        'booking_status': 'future',
      });
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final response = await _supabase
          .from('user_bookings')
          .select('*, charging_stations(name, address)')
          .eq('user_id', userId)
          .order('booking_date', ascending: false)
          .order('start_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user bookings: $e');
      rethrow;
    }
  }
}
