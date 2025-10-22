import 'package:flutter/material.dart';

class MyVehicleView extends StatelessWidget {
  const MyVehicleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 64.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildVehicleOption(context, 'Car', 'assets/e-car.png'),
                  _buildVehicleOption(context, 'Bike', 'assets/e-bike.png'),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feature to be implemented later.'),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(bottom: 120.0, left: 16.0, right: 16.0),
                    ),
                  );
                },
                child: const Text('Add Vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleOption(BuildContext context, String name, String imagePath) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Handle vehicle selection
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
