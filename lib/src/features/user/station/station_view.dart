import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../booking/booking_view.dart'; // Import for BookingView
import '../favorites/favorites_service.dart'; // Import for FavoritesService
import 'direction_view.dart';
import '../../admin/station_management/manage_stations_view.dart'; // For Station model

class StationView extends StatefulWidget {
  final Station station;
  final bool isAdmin; 

  const StationView({
    super.key,
    required this.station,
    this.isAdmin = false, 
  });

  @override
  State<StationView> createState() => _StationViewState();
}

class _StationViewState extends State<StationView> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true; 
  late FavoritesService _favoritesService;
  String? _userId;
  late int _stationId;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;
    _favoritesService = FavoritesService(supabaseClient);
    _userId = supabaseClient.auth.currentUser?.id;
    _stationId = widget.station.stationId;

    if (_userId != null && !widget.isAdmin) { 
      _checkInitialFavoriteStatus();
    } else {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _checkInitialFavoriteStatus() async {
    if (_userId == null) return;
    setState(() {
      _isLoadingFavorite = true;
    });
    try {
      final isFav = await _favoritesService.isFavorite(_userId!, _stationId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      debugPrint("Error checking initial favorite status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking favorite status: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userId == null || _isLoadingFavorite || widget.isAdmin) return; 

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(_userId!, _stationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Removed from favorites"), duration: Duration(seconds: 1)),
          );
        }
      } else {
        await _favoritesService.addFavorite(_userId!, _stationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Added to favorites"), duration: Duration(seconds: 1)),
          );
        }
      }
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating favorite: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String localImageAssetPath = "assets/ev-charging.jpg";
    // Removed: const String stationStatus = "Open 24 hour";
    const String distance = "4.5 km"; // This should ideally come from the station data or be calculated
    // Removed: const String cost = "\$15.00 / hour";
    const String parking = "Free"; // This could also be a field in station data
    const List<String> amenities = ["Wifi", "Gym", "Park", "Parking"]; // This could also be from station data
    
    const String carChargerName = "Car Charger";
    const IconData carChargerIcon = Icons.directions_car_filled_rounded;
    const String bikeChargerName = "Bike Charger";
    const IconData bikeChargerIcon = Icons.two_wheeler_rounded;

    Map<String, IconData> amenityIcons = {
      "Wifi": Icons.wifi,
      "Gym": Icons.fitness_center,
      "Park": Icons.park,
      "Parking": Icons.local_parking,
    };

    // Determine status text and color
    String displayStatus = widget.station.status.isNotEmpty 
        ? widget.station.status[0].toUpperCase() + widget.station.status.substring(1)
        : "Unknown";
    Color statusColor = widget.station.status.toLowerCase() == 'available' 
        ? Colors.green 
        : (widget.station.status.toLowerCase() == 'offline' ? Colors.red : Colors.grey);

    bool isStationOffline = widget.station.status.toLowerCase() == 'offline';

    // Determine if charger cards should be shown
    final bool showCarCharger = widget.station.carChargerCapacity != null && widget.station.carChargerCapacity!.isNotEmpty;
    final bool showBikeCharger = widget.station.bikeChargerCapacity != null && widget.station.bikeChargerCapacity!.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    localImageAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint("Error loading asset image: $error");
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Image not found", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              if (!widget.isAdmin)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: _isLoadingFavorite
                        ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.grey,
                            ),
                            iconSize: 26,
                            onPressed: (_userId == null) ? null : _toggleFavorite,
                          ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            displayStatus, // Use dynamic status
                            style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            distance, // Keep distance for now, assuming it might come from elsewhere
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Removed: _buildInfoRow("Cost :", cost),
                  _buildInfoRow("Parking :", parking), // Kept parking for now
                  _buildInfoRow("Address :", widget.station.address, isExpanded: true),
                  const SizedBox(height: 24),
                  const Text(
                    "Amenities :",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: amenities.length,
                      itemBuilder: (context, index) {
                        final amenityName = amenities[index];
                        return _buildAmenityChip(
                          amenityName,
                          amenityIcons[amenityName] ?? Icons.help_outline,
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Chargers :",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (showCarCharger)
                    _buildChargerCard(carChargerName, widget.station.carChargerCapacity!, carChargerIcon),
                  if (showCarCharger && showBikeCharger) // Add spacing only if both are shown
                    const SizedBox(height: 12),
                  if (showBikeCharger)
                    _buildChargerCard(bikeChargerName, widget.station.bikeChargerCapacity!, bikeChargerIcon),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DirectionView(
                        stationPosition: LatLng(widget.station.latitude, widget.station.longitude),
                        stationName: widget.station.name,
                      ),
                    ),
                  );
                },
                child: const Text("Get direction", style: TextStyle(fontSize: 16)),
              ),
            ),
            if (!widget.isAdmin) ...[ 
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStationOffline ? Colors.grey.shade400 : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (isStationOffline) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Station is currently offline and cannot be booked.')),
                      );
                    } else {
                      debugPrint("Booking a slot at ${widget.station.name}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BookingView(stationId: widget.station.stationId)),
                      );
                    }
                  },
                  child: const Text("Book a slot", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isExpanded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          if (isExpanded)
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(String name, IconData icon) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black54, size: 28),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChargerCard(String name, String capacity, IconData iconData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: Colors.black87, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  capacity, // This will now display the dynamic capacity
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
