import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testing/src/features/user/booking/booking_service.dart';
import 'package:testing/src/features/user/station/direction_view.dart';
import 'schedules_view.dart'; // Contains Booking, BookingStatus, VehicleType
import 'reschedule_view.dart';

class BookingDetailView extends StatefulWidget {
  final Booking booking;

  const BookingDetailView({super.key, required this.booking});

  @override
  State<BookingDetailView> createState() => _BookingDetailViewState();
}

class _BookingDetailViewState extends State<BookingDetailView> {
  late final BookingService _bookingService;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService(Supabase.instance.client);
  }

  Future<void> _showCancelConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to cancel this booking?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBooking() async {
    if (_isCanceling) return;

    setState(() {
      _isCanceling = true;
    });

    try {
      await _bookingService.updateBookingStatus(widget.booking.id, 'failed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking canceled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error canceling booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCanceling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            title: const Text('Booking Details'),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Station Details'),
                    const SizedBox(height: 16),
                    _buildStationInfo(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Booking Timeline'),
                    const SizedBox(height: 16),
                    _buildTimeline(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Vehicle & Billing'),
                    const SizedBox(height: 16),
                    _buildVehicleAndBillingInfo(context),
                    if (widget.booking.displayStatus == BookingStatus.upcoming) ...[
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
    );
  }

  Widget _buildStationInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.booking.stationName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.booking.address,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DirectionView(
                    stationPosition: widget.booking.stationPosition,
                    stationName: widget.booking.stationName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.directions),
            label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTimelineTile(
            context,
            icon: Icons.calendar_today,
            label: 'Date',
            value: DateFormat('dd MMMM yyyy').format(widget.booking.startTime),
            isFirst: true,
          ),
          _buildTimelineTile(
            context,
            icon: Icons.access_time,
            label: 'Time',
            value: '${DateFormat('hh:mm a').format(widget.booking.startTime)} - ${DateFormat('hh:mm a').format(widget.booking.endTime)}',
          ),
          _buildTimelineTile(
            context,
            icon: Icons.hourglass_bottom,
            label: 'Duration',
            value: '${widget.booking.endTime.difference(widget.booking.startTime).inHours} hours',
          ),
          _buildTimelineTile(
            context,
            icon: Icons.info_outline,
            label: 'Status',
            value: widget.booking.displayStatus.name[0].toUpperCase() + widget.booking.displayStatus.name.substring(1),
            valueColor: _getStatusColor(widget.booking.displayStatus),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, {required IconData icon, required String label, required String value, bool isFirst = false, bool isLast = false, Color? valueColor}) {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.booking.displayStatus).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _getStatusColor(widget.booking.displayStatus), size: 20),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: valueColor ?? Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleAndBillingInfo(BuildContext context) {
    String vehicleName = widget.booking.vehicleType == VehicleType.car ? 'Electric Car' : 'Electric Bike';
    String imagePath = widget.booking.vehicleType == VehicleType.car
        ? 'lib/src/features/user/profile/asset/E-car.png'
        : 'lib/src/features/user/profile/asset/e-bike.png';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(imagePath, width: 50, height: 50, errorBuilder: (c, o, s) => const Icon(Icons.error)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicleName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Your selected vehicle', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          if (widget.booking.displayStatus == BookingStatus.completed) ...[
            const Divider(height: 32),
            _buildStyledInfoRow(context, Icons.flash_on, 'Energy Consumed', '${widget.booking.energyConsumed.toStringAsFixed(2)} kWh'),
            const SizedBox(height: 16),
            _buildStyledInfoRow(context, Icons.money, 'Total Cost', '₹${widget.booking.totalCost.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RescheduleView(booking: widget.booking),
                ),
              );
            },
            icon: Icon(Icons.edit_calendar, color: Colors.blue.shade700),
            label: Text(
              'Reschedule',
              style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.blue.shade700, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isCanceling ? null : _showCancelConfirmationDialog,
            icon: _isCanceling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 16),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.active:
        return Colors.orange.shade700;
      case BookingStatus.upcoming:
        return Colors.blue.shade700;
      case BookingStatus.completed:
        return Colors.green.shade700;
      case BookingStatus.canceled:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
