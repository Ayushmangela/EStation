import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StationCard extends StatelessWidget {
  final String name;
  final String address;
  final String chargerType;
  final String capacity;
  final String status;
  final VoidCallback onViewPressed;
  final VoidCallback onBookPressed;

  const StationCard({
    super.key,
    required this.name,
    required this.address,
    this.chargerType = "AC/DC Charger",
    this.capacity = "N/A",
    this.status = "Unknown",
    required this.onViewPressed,
    required this.onBookPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == "Available" ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.grey),
                onPressed: () => debugPrint("Favorite tapped for $name"),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Address
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip(Icons.ev_station, chargerType),
              _infoChip(Icons.bolt, "$capacity kW"),
              _infoChip(
                status == "Available" ? Icons.check_circle : Icons.cancel,
                status,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onViewPressed,
                  child: const Text("View"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onBookPressed,
                  child: const Text("Book"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color color = Colors.black}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}
