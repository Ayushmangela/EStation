import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final SupabaseClient _supabaseClient;

  // Constructor updated to store the SupabaseClient instance
  FavoritesService(this._supabaseClient);

  /// Adds a station to the user's favorites.
  Future<void> addFavorite(String userId, int stationId) async {
    try {
      await _supabaseClient.from('favorites').insert({
        'user_id': userId,
        'station_id': stationId,
      });
      // Supabase Dart client v1+ throws a PostgrestException on failure.
      print('FavoritesService: Successfully added favorite for user $userId, station $stationId');
    } catch (e) {
      print('FavoritesService: Error adding favorite for user $userId, station $stationId - $e');
      throw Exception('Failed to add favorite: ${e.toString()}');
    }
  }

  /// Removes a station from the user's favorites.
  Future<void> removeFavorite(String userId, int stationId) async {
    try {
      await _supabaseClient
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
      // Supabase Dart client v1+ throws a PostgrestException on failure if the delete encounters an issue
      // (though for a delete, if the row doesn't exist, it typically doesn't error).   
      print('FavoritesService: Successfully removed favorite for user $userId, station $stationId');
    } catch (e) {
      print('FavoritesService: Error removing favorite for user $userId, station $stationId - $e');
      throw Exception('Failed to remove favorite: ${e.toString()}');
    }
  }

  /// Checks if a station is favorited by the user.
  Future<bool> isFavorite(String userId, int stationId) async {
    try {
      final response = await _supabaseClient
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('station_id', stationId)
          .maybeSingle(); // .maybeSingle() returns one row or null, perfect for checking existence.
      
      return response != null;
    } catch (e) {
      print('FavoritesService: Error checking favorite status for user $userId, station $stationId - $e');
      throw Exception('Failed to check favorite status: ${e.toString()}');
    }
  }


  /// Fetches all favorite stations for a user, including station details.
  Future<List<Map<String, dynamic>>> getFavoriteStations(String userId) async {
    try {
      final response = await _supabaseClient
          .from('favorites')
          .select('charging_stations(*)') // This uses the relationship to fetch station details.
                                        // Ensure the relationship is set up in your Supabase dashboard:
                                        // favorites.station_id -> charging_stations.station_id
          .eq('user_id', userId);

      // The response from Supabase (if successful) is already a List<Map<String, dynamic>>.
      // Each item in the list will be a map from the 'favorites' table,
      // and it will contain a nested 'charging_stations' map with the station details.
      return response;
    } catch (e) {
      print('FavoritesService: Error fetching favorite stations for user $userId - $e');
      throw Exception('Failed to fetch favorite stations: ${e.toString()}');
    }
  }
}
