import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

// Import the views for the tabs
import '../../user/map/map_view.dart';
import '../station_management/manage_stations_view.dart';

class AdminHomeView extends StatefulWidget {
const AdminHomeView({super.key});

@override
State<AdminHomeView> createState() => _AdminHomeViewState();
}


class _AdminHomeViewState extends State<AdminHomeView> {
int _selectedIndex = 0;

final List<Widget> _pages = [
    const UserMapView(isAdmin: true), // Pass isAdmin: true
const ManageStationsView(),
];


@override
Widget build(BuildContext context) {
return Scaffold(
extendBody: true, // Makes the nav bar float
body: IndexedStack(
index: _selectedIndex,
children: _pages,
),
bottomNavigationBar: CircleNavBar(
activeIndex: _selectedIndex,
onTap: (index) {
setState(() {
_selectedIndex = index;
});
},
// Define the tabs
activeIcons: const [
Icon(Icons.map_outlined, color: Colors.white),
Icon(Icons.edit_location_alt_outlined, color: Colors.white),
],
inactiveIcons: const [
Icon(Icons.map_outlined, color: Colors.white),
Icon(Icons.edit_location_alt_outlined, color: Colors.white),
],
levels: const ["Map", "Manage"],
activeLevelsStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: Colors.white,
),
inactiveLevelsStyle: const TextStyle(
fontSize: 12,
color: Colors.white70,
),


// Style the nav bar
padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
circleWidth: 45,
height: 70,
color: Colors.black, // Navbar background color
circleColor: Colors.green, // Moving circle color
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
