import 'package:flutter/material.dart';
import 'favorites_service.dart';
// You will likely need your station model here
// import '../../models/station_model.dart'; // Assuming you have a station model

class FavoritesController with ChangeNotifier {
  final FavoritesService _favoritesService;
  final String _userId; // Assuming you get the current user's ID

  FavoritesController(this._favoritesService, this._userId) {
    fetchFavoriteStations();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _favoriteStations = []; // Or List<StationModel> if you have a model
  List<Map<String, dynamic>> get favoriteStations => _favoriteStations;

  Future<void> fetchFavoriteStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _favoriteStations = await _favoritesService.getFavoriteStations(_userId);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching favorite stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optional: Add methods to add/remove favorites directly from this controller
  // if the FavoritesView will also have options to unfavorite items directly from the list.
  Future<void> removeFromFavorites(int stationId) async {
    // Similar loading/error handling as fetchFavoriteStations
    try {
      await _favoritesService.removeFavorite(_userId, stationId);
      // Refresh the list after removing
      await fetchFavoriteStations(); 
    } catch (e) {
      // Handle error, maybe set an error message for the specific item or view
      print('Error removing favorite from controller: $e');
    }
  }
}
