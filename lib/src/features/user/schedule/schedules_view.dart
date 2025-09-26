import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testing/main.dart';
import '../booking/booking_service.dart';

void main() {
  runApp(const MyApp());
}

enum BookingFilter { active, upcoming, past }

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
      navigatorObservers: [appRouteObserver],
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
  final VehicleType vehicleType;

  Booking({
    required this.id,
    required this.stationName,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.vehicleType,
    this.totalCost = 0.0,
    this.energyConsumed = 0.0,
  });

  static Booking? fromMap(Map<String, dynamic> map) {
    try {
      final station = map['charging_stations'];
      final statusString = map['booking_status'] as String;
      BookingStatus status;
      switch (statusString) {
        case 'active':
          status = BookingStatus.active;
          break;
        case 'future':
          status = BookingStatus.upcoming;
          break;
        case 'completed':
          status = BookingStatus.completed;
          break;
        case 'failed':
          status = BookingStatus.canceled;
          break;
        default:
          status = BookingStatus.canceled;
      }

      DateTime? startTime;
      if (map['booking_date'] != null && map['start_time'] != null) {
        startTime = DateTime.parse('${map['booking_date']} ${map['start_time']}');
      }

      DateTime? endTime;
      if (map['booking_date'] != null && map['end_time'] != null) {
        endTime = DateTime.parse('${map['booking_date']} ${map['end_time']}');
      }

      if (startTime == null) {
        return null;
      }

      return Booking(
        id: map['booking_id'].toString(),
        stationName: station?['name'] ?? 'Unknown Station',
        address: station?['address'] ?? 'No address',
        startTime: startTime,
        endTime: endTime ?? startTime.add(const Duration(hours: 1)), // Default to 1 hour if end time is null
        status: status,
        vehicleType: (map['vehicle_type'] as String) == 'car' ? VehicleType.car : VehicleType.bike,
      );
    } catch (e) {
      print("Error parsing booking data: $e");
      print("Problematic data: $map");
      return null;
    }
  }
}

enum BookingStatus { active, upcoming, completed, canceled }

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with RouteAware {
  BookingFilter _selectedFilter = BookingFilter.active;
  late final BookingService _bookingService;
  late final String? _userId;
  Future<List<Booking>>? _bookingsFuture;

  List<Booking> _allBookings = [];
  List<Booking> _activeBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService(Supabase.instance.client);
    _userId = Supabase.instance.client.auth.currentUser?.id;
    if (_userId != null) {
      _bookingsFuture = _fetchUserBookings();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      appRouteObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // This method is called when the user navigates back to this page.
    // We re-fetch the bookings to ensure the list is up-to-date.
    if (mounted) {
      setState(() {
        _bookingsFuture = _fetchUserBookings();
      });
    }
    super.didPopNext();
  }

  Future<List<Booking>> _fetchUserBookings() async {
    final bookingsData = await _bookingService.getUserBookings(_userId!);
    final bookings = bookingsData.map((map) => Booking.fromMap(map)).where((b) => b != null).cast<Booking>().toList();
    // No need to call setState here as the FutureBuilder will handle the state update
    _allBookings = bookings;
    _filterBookings();
    return bookings;
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
      body: _userId == null
          ? const Center(child: Text('Please log in to see your bookings.'))
          : FutureBuilder<List<Booking>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_busy,
                    message: "You have no bookings yet.",
                    buttonText: "Book a Slot",
                  );
                }

                // We need to filter the bookings based on the snapshot data
                _allBookings = snapshot.data!;
                _filterBookings();

                return Column(
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
                );
              },
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
