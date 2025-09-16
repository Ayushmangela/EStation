import 'package:flutter/material.dart';

class StationCard extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback onViewPressed;
  final VoidCallback onBookPressed;

  const StationCard({
    super.key,
    required this.name,
    required this.address,
    required this.onViewPressed,
    required this.onBookPressed,
  });

  Widget _buildChargerInfoBox({
    required IconData icon,
    required String title,
    required String capacityInfo,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced vertical padding
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 0), // Reduced space
                  Text(
                    capacityInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0, // Target height
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // Reduced top/bottom card padding
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.grey),
                iconSize: 28,
                onPressed: () => debugPrint("Favorite tapped for $name"),
              ),
            ],
          ),
          const SizedBox(height: 0), // Reduced space between name and address
          // Address
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced space before charger info
          // Static Charger Info Boxes
          Row(
            children: [
              _buildChargerInfoBox(
                icon: Icons.directions_car,
                title: "Car Charger",
                capacityInfo: "Capacity: 60KW",
              ),
              const SizedBox(width: 10),
              _buildChargerInfoBox(
                icon: Icons.two_wheeler,
                title: "Bike Charger",
                capacityInfo: "Capacity: 15KW",
              ),
            ],
          ),
          const Spacer(), // Pushes buttons to the bottom
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 8), // Reduced vertical padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onViewPressed,
                  child: const Text("View station"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8), // Reduced vertical padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                     textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onBookPressed,
                  child: const Text("Book Charger"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
