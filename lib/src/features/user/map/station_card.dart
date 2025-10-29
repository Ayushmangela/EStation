import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../admin/station_management/manage_stations_view.dart';

class StationCard extends StatefulWidget {
  final int stationId;
  final String name;
  final String address;
  final double? distanceKm;
  final VoidCallback onViewPressed;
  final VoidCallback onBookPressed;
  final String viewLabel;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final bool isLoadingFavorite;
  final bool isAdmin;
  final Station? station; // Add this to accept the full station object

  const StationCard({
    super.key,
    required this.stationId,
    required this.name,
    required this.address,
    this.distanceKm,
    required this.onViewPressed,
    required this.onBookPressed,
    this.viewLabel = "View Station",
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.isLoadingFavorite = false,
    this.isAdmin = false,
    this.station, // Add this to the constructor
  });

  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  late Future<List<Map<String, dynamic>>> _chargerCapacitiesFuture;
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    _chargerCapacitiesFuture = _fetchChargerCapacities();
  }

  Future<List<Map<String, dynamic>>> _fetchChargerCapacities() async {
    try {
      final response = await Supabase.instance.client
          .from('station_charger_capacity')
          .select('vehicle_type, capacity_value')
          .eq('station_id', widget.stationId);
      
      if (mounted && _hasNetworkError) {
        setState(() {
          _hasNetworkError = false;
        });
      }
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        // Using addPostFrameCallback to safely update state after the build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasNetworkError = true;
            });
          }
        });
      }
      // Re-throw to be handled by the FutureBuilder.
      throw e;
    }
  }

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
      height: 225,
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
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.isAdmin)
                widget.isLoadingFavorite
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
                          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: widget.isFavorite ? Colors.red : Colors.grey,
                        ),
                        iconSize: 28,
                        onPressed: widget.onFavoriteToggle,
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
                  widget.address,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Distance Text
          Text(
            widget.distanceKm != null
                ? "${widget.distanceKm!.toStringAsFixed(2)} km away"
                : "Distance unknown",
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Charger Info Row
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _chargerCapacitiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                if (snapshot.error.toString().contains('SocketException')) {
                  return const Center(
                    child: Text('No internet connection'),
                  );
                }
                return const Center(
                  child: Text('Error loading charger info'),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No charger info available');
              } else {
                final capacities = snapshot.data!;
                List<Widget> chargerInfoWidgets = [];
                for (int i = 0; i < capacities.length; i++) {
                    final capacity = capacities[i];
                    final vehicleType = capacity['vehicle_type'];
                    final capacityValue = capacity['capacity_value'];
                    IconData icon;
                    String title;

                    if (vehicleType == 'car') {
                      icon = Icons.directions_car;
                      title = "Car Charger";
                    } else if (vehicleType == 'bike') {
                      icon = Icons.two_wheeler;
                      title = "Bike Charger";
                    } else {
                      // Default case if needed
                      icon = Icons.power;
                      title = "Charger";
                    }

                    chargerInfoWidgets.add(_buildChargerInfoBox(
                      icon: icon,
                      title: title,
                      capacityInfo: "Capacity: $capacityValue",
                    ));

                    if (i < capacities.length - 1) {
                      chargerInfoWidgets.add(const SizedBox(width: 10));
                    }
                }
                return Row(
                  children: chargerInfoWidgets,
                );
              }
            },
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
                  onPressed: _hasNetworkError ? null : widget.onViewPressed,
                  child: Text(widget.viewLabel),
                ),
              ),
              if (!widget.isAdmin) ...[
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
                    onPressed: _hasNetworkError ? null : widget.onBookPressed,
                    child: const Text("Book Charger"),
                  ), 
                ),
              ],
            ],
          )
        ],
      ),
    );
  }
}
