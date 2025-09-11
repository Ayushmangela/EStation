import 'package:flutter/material.dart';

class AdminStationFormView extends StatelessWidget {
  // final Station? station; // Optional: Pass station for editing
  const AdminStationFormView({super.key /*, this.station*/});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(/*station == null ?*/ 'Add Station' /*: 'Edit Station'*/)),
      body: const Center(child: Text('Admin Station Form - Placeholder')),
    );
  }
}
