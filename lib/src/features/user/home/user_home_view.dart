import 'package:flutter/material.dart';
import '../charging/charging_view.dart';
import '../battery/battery_view.dart';
import '../profile/profile_view.dart';
import '../map/map_view.dart';


class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  int _currentIndex = 0;

  // List of pages for bottom navigation.
  // These are placeholder widgets. You should create these files.
  final List<Widget> _pages = [
    const UserMapView(), // 👈 Home tab shows the map
    const ChargingView(),
    const BatteryView(),
    const ProfileView(),
  ];

  // List of bottom navigation items
  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
    BottomNavigationBarItem(icon: Icon(Icons.ev_station), label: 'Charger'),
    BottomNavigationBarItem(icon: Icon(Icons.battery_charging_full), label: 'Battery'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _bottomNavItems,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

// You will need to create these placeholder view files for the other tabs
class ChargingView extends StatelessWidget {
  const ChargingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Charging View'));
}

class BatteryView extends StatelessWidget {
  const BatteryView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Battery View'));
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profile View'));
}