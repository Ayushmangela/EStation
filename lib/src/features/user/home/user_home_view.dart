import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

// Your views
import '../map/map_view.dart';
import '../charging/charging_view.dart';
// import '../battery/battery_view.dart'; // Replaced by BookingsPage
import '../schedule/schedules_view.dart'; // Added for BookingsPage
import '../profile/profile_view.dart';

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  int selectedIndex = 0;

  final List<Widget> _pages = [
    const UserMapView(),
    const ChargingView(),
    const BookingsPage(), // This is the content from schedules_view.dart
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // navbar floats above content
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CircleNavBar(
        activeIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        // Active icons inside circle
        activeIcons: const [
          Icon(Icons.map_outlined, color: Colors.white),
          Icon(Icons.ev_station, color: Colors.white),
          Icon(Icons.calendar_month_outlined, color: Colors.white),
          Icon(Icons.person_outline, color: Colors.white),
        ],
        // Labels outside circle
        levels: const ["Map", "Charge", "Schedule", "Profile"], // Changed "Bookings" to "Schedule"
        activeLevelsStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        inactiveLevelsStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
        inactiveIcons: const [
          Icon(Icons.map_outlined, color: Colors.white),
          Icon(Icons.ev_station, color: Colors.white),
          Icon(Icons.calendar_month_outlined, color: Colors.white),
          Icon(Icons.person_outline, color: Colors.white),
        ],
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        circleWidth: 45,
        height: 70,
        color: Colors.black, // navbar background
        circleColor: Colors.green, // moving circle color
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        elevation: 10,
        tabCurve: Curves.decelerate,
        iconCurve: Curves.linear,
        tabDurationMillSec: 500,
        iconDurationMillSec: 100,
      ),
    );
  }
}
