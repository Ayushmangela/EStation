import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testing/src/features/admin/station_management/manage_stations_view.dart';
import 'package:testing/src/features/user/station/station_view.dart';
import 'favorites_controller.dart';
import 'favorites_service.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Favorites')),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    final supabaseClient = Supabase.instance.client;
    final favoritesService = FavoritesService(supabaseClient);

    return ChangeNotifierProvider(
      create: (_) => FavoritesController(favoritesService, userId),
      child: Consumer<FavoritesController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Favorites'),
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
            ),
            body: _buildFavoritesList(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, FavoritesController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => controller.fetchFavoriteStations(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.favoriteStations.isEmpty) {
      return const Center(
        child: Text(
          'You haven\'t added any favorite stations yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: controller.favoriteStations.length,
      itemBuilder: (context, index) {
        final station = controller.favoriteStations[index];
        final stationData = station['charging_stations'];
        final stationName = stationData?['name'] ?? 'Unknown Station';
        final stationAddress = stationData?['address'] ?? 'No address';
        final stationId = stationData?['station_id'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(stationName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(stationAddress, style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () {
                if (stationId != null) {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Remove Favorite?'),
                        content: Text('Are you sure you want to remove $stationName from your favorites?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Remove', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              controller.removeFromFavorites(stationId);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
            onTap: () {
              if (stationData != null && stationData is Map<String, dynamic>) {
                try {
                  final stationObject = Station(
                    stationId: stationData['station_id'] as int,
                    name: stationData['name'] as String,
                    address: stationData['address'] as String,
                    latitude: (stationData['latitude'] as num).toDouble(),
                    longitude: (stationData['longitude'] as num).toDouble(),
                    operator: stationData['operator'] as String?,
                    hasBikeCharger: stationData['has_bike_charger'] as bool,
                    hasCarCharger: stationData['has_car_charger'] as bool,
                    status: stationData['status'] as String,
                    createdAt: DateTime.parse(stationData['created_at'] as String),
                    updatedAt: DateTime.parse(stationData['updated_at'] as String),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StationView(station: stationObject),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open station details: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open station details: data is missing.')),
                );
              }
            },
          ),
        );
      },
    );
  }
}
