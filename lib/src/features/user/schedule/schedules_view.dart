import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

enum BookingFilter { active, upcoming, past }

// Add VehicleType enum
enum VehicleType { car, bike }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookings UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.green[100],
          labelStyle: const TextStyle(color: Colors.black87),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Colors.transparent),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        ),
      ),
      home: const BookingsPage(),
    );
  }
}

class Booking {
  final String id;
  final String stationName;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double totalCost;
  final double energyConsumed;
  final VehicleType vehicleType; // Added vehicleType

  Booking({
    required this.id,
    required this.stationName,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.vehicleType, // Added to constructor
    this.totalCost = 0.0,
    this.energyConsumed = 0.0,
  });
}

enum BookingStatus { active, upcoming, completed, canceled }

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  BookingFilter _selectedFilter = BookingFilter.active;

  final List<Booking> _allBookings = [
    Booking(
      id: '1',
      stationName: 'Jio-bp Pulse - BKC',
      address: 'Bandra Kurla Complex, Mumbai',
      startTime: DateTime.now().subtract(const Duration(minutes: 15)),
      endTime: DateTime.now().add(const Duration(minutes: 45)),
      status: BookingStatus.active,
      vehicleType: VehicleType.car, // Added vehicle type
      energyConsumed: 8.5,
      totalCost: 127.50,
    ),
    Booking(
      id: '2',
      stationName: 'ChargeGrid - Phoenix Mall',
      address: 'Lower Parel, Mumbai',
      startTime: DateTime.now().add(const Duration(hours: 3)),
      endTime: DateTime.now().add(const Duration(hours: 4)),
      status: BookingStatus.upcoming,
      vehicleType: VehicleType.bike, // Added vehicle type
    ),
    Booking(
      id: '3',
      stationName: 'Tata Power EZ Charge',
      address: 'Viviana Mall, Thane',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 6)),
      status: BookingStatus.upcoming,
      vehicleType: VehicleType.car, // Added vehicle type
    ),
    Booking(
      id: '4',
      stationName: 'Statiq Charging Station',
      address: 'Seawoods Grand Central, Navi Mumbai',
      startTime: DateTime.now().subtract(const Duration(days: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
      status: BookingStatus.completed,
      vehicleType: VehicleType.bike, // Added vehicle type
      totalCost: 250.00,
      energyConsumed: 12.5,
    ),
    Booking(
      id: '5',
      stationName: 'ChargeGrid - Phoenix Mall',
      address: 'Lower Parel, Mumbai',
      startTime: DateTime.now().subtract(const Duration(days: 5)),
      endTime: DateTime.now().subtract(const Duration(days: 5, hours: -1)),
      status: BookingStatus.canceled,
      vehicleType: VehicleType.car, // Added vehicle type
    ),
  ];

  late List<Booking> _activeBookings;
  late List<Booking> _upcomingBookings;
  late List<Booking> _pastBookings;

  @override
  void initState() {
    super.initState();
    _filterBookings();
  }

  void _filterBookings() {
    _activeBookings =
        _allBookings.where((b) => b.status == BookingStatus.active).toList();
    _upcomingBookings =
        _allBookings.where((b) => b.status == BookingStatus.upcoming).toList();
    _pastBookings = _allBookings
        .where((b) =>
            b.status == BookingStatus.completed ||
            b.status == BookingStatus.canceled)
        .toList();

    _upcomingBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
    _pastBookings.sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: BookingFilter.values.map((filter) {
          bool isSelected = _selectedFilter == filter;
          String filterName = filter.name[0].toUpperCase() + filter.name.substring(1);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filterName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              selectedColor: Theme.of(context).chipTheme.selectedColor,
              backgroundColor: Theme.of(context).chipTheme.backgroundColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green[800] : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: isSelected 
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.green[700]!, width: 1.5)
                    )
                  : Theme.of(context).chipTheme.shape,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilteredBookingsList() {
    List<Booking> bookingsToDisplay;
    String emptyMessage;
    IconData emptyIcon; // Still used for EmptyStateWidget

    switch (_selectedFilter) {
      case BookingFilter.active:
        bookingsToDisplay = _activeBookings;
        emptyMessage = "No active sessions right now.";
        emptyIcon = Icons.bolt;
        break;
      case BookingFilter.upcoming:
        bookingsToDisplay = _upcomingBookings;
        emptyMessage = "No upcoming bookings.";
        emptyIcon = Icons.event_available;
        break;
      case BookingFilter.past:
        bookingsToDisplay = _pastBookings;
        emptyMessage = "No past sessions available.";
        emptyIcon = Icons.history;
        break;
    }

    if (bookingsToDisplay.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        message: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: bookingsToDisplay.length,
      itemBuilder: (context, index) {
        return BookingListItem(booking: bookingsToDisplay[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              "Recent",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          _buildFilterChips(),
          Expanded(child: _buildFilteredBookingsList()),
        ],
      ),
    );
  }
}

class BookingListItem extends StatelessWidget {
  final Booking booking;
  const BookingListItem({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    String imagePath;
    switch (booking.vehicleType) {
      case VehicleType.car:
        imagePath = 'lib/src/features/user/profile/asset/E-car.png'; // Updated path
        break;
      case VehicleType.bike:
        imagePath = 'lib/src/features/user/profile/asset/e-bike.png'; // Updated path
        break;
    }

    // Icon for status is still relevant for context, can be overlaid or used elsewhere if design changes
    IconData statusIcon;
    Color statusIconColor;
    switch (booking.status) {
      case BookingStatus.active:
        statusIcon = Icons.bolt;
        statusIconColor = Colors.orange;
        break;
      case BookingStatus.upcoming:
        statusIcon = Icons.event_available;
        statusIconColor = Colors.blue;
        break;
      case BookingStatus.completed:
        statusIcon = Icons.check_circle_outline;
        statusIconColor = Colors.green;
        break;
      case BookingStatus.canceled:
        statusIcon = Icons.cancel_outlined;
        statusIconColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0), // Add padding if images are too large
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain, // Or BoxFit.cover, depending on image aspect ratio
              errorBuilder: (context, error, stackTrace) {
                // Fallback for missing images
                print("Error loading image: $error at $imagePath"); // For debugging
                return Icon(Icons.directions_car, color: Colors.grey[700], size: 28);
              },
            ),
          ),
        ),
        title: Text(
          booking.stationName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.address,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(statusIcon, color: statusIconColor, size: 14), // Status icon next to date
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd-MM-yyyy | hh:mm a').format(booking.startTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () {
          // TODO: Handle item tap, e.g., navigate to booking details
        },
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonText;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonText!, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              )
            ]
          ],
        ),
      ),
    );
  }
}
