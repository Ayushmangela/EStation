import 'package:flutter/material.dart';

class AdminStationListView extends StatelessWidget {
  const AdminStationListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Stations')),
      body: const Center(child: Text('Admin Station List - Placeholder')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Station Form View
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
