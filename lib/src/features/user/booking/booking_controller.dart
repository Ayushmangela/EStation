import 'package:flutter/material.dart';
import 'booking_service.dart';

class BookingController {
  final BookingService _bookingService;

  BookingController(this._bookingService);

  Future<List<Map<String, dynamic>>> getBookedSlots({
    required int stationId,
    required String vehicleType,
    required DateTime date,
  }) async {
    try {
      return await _bookingService.getBookedSlots(
        stationId: stationId,
        vehicleType: vehicleType,
        date: date,
      );
    } catch (e) {
      debugPrint('Error in BookingController: $e');
      rethrow;
    }
  }
}