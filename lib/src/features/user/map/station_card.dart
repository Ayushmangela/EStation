import 'package:flutter/material.dart';

class StationCard extends StatelessWidget {
  final int stationId;
  final String name;
  final String address;
  final double? distanceKm; // Added distance
  final VoidCallback onViewPressed;
  final VoidCallback onBookPressed;
  final String viewLabel;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final bool isLoadingFavorite;

  const StationCard({
    super.key,
    required this.stationId,
    required this.name,
    required this.address,
    this.distanceKm, // Added distance
    required this.onViewPressed,
    required this.onBookPressed,
    this.viewLabel = "View Station",
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.isLoadingFavorite = false,
  });

  Widget _buildChargerInfoBox({
    required IconData icon,
    required String title,
    required String capacityInfo,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
      // Adjusted height to accommodate distance, might need further tweaking
      // Consider removing fixed height if content varies significantly
      height: 225, // Changed from 220 to 225
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              isLoadingFavorite
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey,
                        ),
                      ))
                  : IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      iconSize: 28,
                      onPressed: onFavoriteToggle,
                    ),
            ],
          ),
          const SizedBox(height: 4),
          // Address Row
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
          const SizedBox(height: 4), // Added some space before distance
          // Distance Text
          Text(
            distanceKm != null
                ? "${distanceKm!.toStringAsFixed(2)} km away"
                : "Distance unknown",
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Charger Info Row
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
          const Spacer(),
          // Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onViewPressed,
                  child: Text(viewLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
