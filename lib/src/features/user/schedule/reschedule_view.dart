import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testing/src/features/user/booking/booking_service.dart';
import 'schedules_view.dart';

class RescheduleView extends StatefulWidget {
  final Booking booking;

  const RescheduleView({super.key, required this.booking});

  @override
  State<RescheduleView> createState() => _RescheduleViewState();
}

class _RescheduleViewState extends State<RescheduleView> {
  late BookingService _bookingService;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<String> _availableSlots = [];
  bool _isLoading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService(Supabase.instance.client);
    _selectedDate = widget.booking.startTime;
    _fetchAvailableSlots();
  }

  Future<void> _fetchAvailableSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookedSlots = await _bookingService.getBookedSlots(
        stationId: widget.booking.stationId,
        vehicleType: widget.booking.vehicleType.name,
        date: _selectedDate,
      );

      // This is a placeholder for generating all possible slots
      final allSlots = List.generate(12, (i) => '${(i + 8).toString().padLeft(2, '0')}:00');
      final available = allSlots.where((slot) => !bookedSlots.any((booked) => booked['start_time'] == slot)).toList();

      setState(() {
        _availableSlots = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching slots: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _fetchAvailableSlots();
      });
    }
  }

  Future<void> _rescheduleBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _bookingService.updateBookingDateTime(widget.booking.id, _selectedDate, _selectedTime!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rescheduled successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rescheduling: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a new date and time for your booking at ${widget.booking.stationName}.'),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Selected Date'),
              subtitle: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            const Text('Available Time Slots:'),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _availableSlots[index];
                        final isSelected = _selectedTime == slot;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTime = slot;
                            });
                          },
                          child: Card(
                            color: isSelected ? Colors.green : Colors.white,
                            child: Center(
                              child: Text(
                                slot,
                                style: TextStyle(color: isSelected ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _rescheduleBooking,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isUpdating
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirm Reschedule'),
        ),
      ),
    );
  }
}
