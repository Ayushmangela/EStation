import 'package:flutter/material.dart';

class UserBookingView extends StatelessWidget {
  const UserBookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: const Center(child: Text('User Bookings - Placeholder')),
    );
  }
}
