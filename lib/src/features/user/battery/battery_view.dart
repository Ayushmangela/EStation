import 'package:flutter/material.dart';

class BatteryView extends StatelessWidget {
  const BatteryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap with a Container to add a background color
    return Container(
      color: Colors.yellow,
      child: const Center(
        child: Text(
          'Battery Page',
          // Change the text color to white to make it visible
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}