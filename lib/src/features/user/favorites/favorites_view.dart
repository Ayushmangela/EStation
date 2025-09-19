import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Assuming you use Provider for state management
import 'favorites_controller.dart';
import 'favorites_service.dart'; // For direct service access if needed, or through controller
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase client instance

// Placeholder for your Station model - replace with your actual model
// class Station {
//   final int id;
//   final String name;
//   final String address;
//   // Add other relevant fields
//   Station({required this.id, required this.name, required this.address});
// }

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming you have a way to get the current user ID, e.g., from Supabase auth
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Favorites')),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    // You'll need to provide FavoritesService and FavoritesController
    // For example, using Provider:
    // Make sure FavoritesService is provided higher up in the widget tree
    // Or create an instance directly if not using a sophisticated state management / DI solution yet.
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
        // Assuming your station data is in a Map<String, dynamic>
        // Adjust if you have a specific Station model
        final station = controller.favoriteStations[index];
        final stationName = station['charging_stations']?['name'] ?? station['name'] ?? 'Unknown Station';
        final stationAddress = station['charging_stations']?['address'] ?? station['address'] ?? 'No address';
        final stationId = station['charging_stations']?['station_id'] ?? station['station_id'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(stationName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(stationAddress, style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red), // Always favorited in this list
              onPressed: () {
                if (stationId != null) {
                   // Show a confirmation dialog before removing
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
              // Optional: Navigate to station details view if you have one
              // Navigator.push(context, MaterialPageRoute(builder: (context) => StationView(station: station['charging_stations'] ?? station)));
              print('Tapped on favorite station: $stationName');
            },
          ),
        );
      },
    );
  }
}
