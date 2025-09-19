import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

// Corrected import to use package notation
import 'package:testing/main.dart'; 

import '../favorites/favorites_service.dart';
import 'map_controller.dart'; 
import 'map_service.dart';    
import 'station_card.dart';
import '../station/station_view.dart';

class UserMapView extends StatefulWidget {
  const UserMapView({super.key});

  @override
  State<UserMapView> createState() => _UserMapViewState();
}

class _UserMapViewState extends State<UserMapView> with RouteAware {
  GoogleMapController? _mapController;
  late final MapController _mapControllerHelper;

  LatLng? _currentPosition;
  String? _mapStyle;
  bool _isLoading = true;
  bool _showListView = false;
  Map<String, dynamic>? _selectedStation;

  late FavoritesService _favoritesService;
  String? _userId;
  final Map<int, bool> _stationFavoriteStatus = {};
  final Map<int, bool> _stationLoadingStatus = {};

  @override
  void initState() {
    super.initState(); 

    final supabase = Supabase.instance.client;
    _favoritesService = FavoritesService(supabase);
    _userId = supabase.auth.currentUser?.id;

    final mapService = MapService(supabase); 
    _mapControllerHelper = MapController(mapService); 

    _initializeMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) { 
      appRouteObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint("UserMapView: didPopNext - refreshing favorite statuses.");
    _refreshVisibleFavoriteStatuses();
    super.didPopNext();
  }
  
  void _refreshVisibleFavoriteStatuses() {
    if (!mounted) return;
    if (!_showListView && _selectedStation != null) {
      final stationId = _selectedStation!['station_id'] as int?;
      if (stationId != null) {
        debugPrint("UserMapView: Refreshing favorite for selected station $stationId");
        _fetchFavoriteStatus(stationId);
      }
    }
    if (_showListView) {
      debugPrint("UserMapView: Clearing favorite cache for list view refresh.");
      _stationFavoriteStatus.clear();
      _stationLoadingStatus.clear(); 
    }
    setState(() {}); 
  }

  Future<void> _fetchFavoriteStatus(int stationId) async {
    if (_userId == null || (_stationLoadingStatus[stationId] ?? false)) return;
    if (mounted) setState(() => _stationLoadingStatus[stationId] = true);
    try {
      final isFav = await _favoritesService.isFavorite(_userId!, stationId);
      if (mounted) setState(() => _stationFavoriteStatus[stationId] = isFav);
    } catch (e) {
      debugPrint("Error fetching fav status for $stationId: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error checking favorite: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _stationLoadingStatus[stationId] = false);
    }
  }

  Future<void> _toggleFavorite(int stationId) async {
    if (_userId == null || (_stationLoadingStatus[stationId] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login or station ID missing/loading.')));
      return;
    }
    if(mounted) setState(() => _stationLoadingStatus[stationId] = true );
    bool currentStatus = _stationFavoriteStatus[stationId] ?? false;
    String message;
    try {
      if (currentStatus) {
        await _favoritesService.removeFavorite(_userId!, stationId);
        message = "Removed from favorites";
      } else {
        await _favoritesService.addFavorite(_userId!, stationId);
        message = "Added to favorites";
      }
      if (mounted) {
        setState(() => _stationFavoriteStatus[stationId] = !currentStatus);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      debugPrint("Error toggling fav for $stationId: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating favorite: ${e.toString()}")));
    } finally {
      if(mounted) setState(() => _stationLoadingStatus[stationId] = false);
    }
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    if (mounted) setState(() => _isLoading = false);
    _loadMapStyle();

    final StationTapCallback onStationSelectedCallback = (station) {
      if (mounted) {
        final stationId = station['station_id'] as int?;
        if (stationId != null && _userId != null && !_stationFavoriteStatus.containsKey(stationId) && !(_stationLoadingStatus[stationId] ?? false)) {
          _fetchFavoriteStatus(stationId);
        }
        setState(() {
          _selectedStation = station;
          _showListView = false;
        });
        _animateToStation(station);
      }
    };

    await _mapControllerHelper.loadStations(onStationSelectedCallback);

    if (mounted) setState(() {}); 
  }

  Future<void> _animateToStation(Map<String, dynamic> station) async {
    final LatLng? stationPosition = station['position'] as LatLng?;
    try {
      if (_mapController != null && stationPosition != null) {
        await _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: stationPosition, zoom: 17)));
      }
    } catch (e) { debugPrint("Error animating to station: $e"); }
  }

  Future<void> _loadMapStyle() async {
    try { _mapStyle = await rootBundle.loadString('assets/map_style.txt'); }
    catch (e) { debugPrint("Error loading map style: $e"); }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { debugPrint("Location services disabled."); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { debugPrint("Location permission denied."); return; }
      }
      if (permission == LocationPermission.deniedForever) { debugPrint("Location permission denied forever."); return; }
      Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _currentPosition = LatLng(p.latitude, p.longitude));
    } catch (e) { debugPrint("Error getting current location: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPosition ?? const LatLng(19.0760, 72.8777), zoom: _currentPosition != null ? 16 : 12),
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              if (_mapStyle != null) { try { await controller.setMapStyle(_mapStyle); } catch (e) { debugPrint("Error setting map style: $e"); } }
            },
            markers: _mapControllerHelper.markers,
            myLocationEnabled: true, myLocationButtonEnabled: true, zoomControlsEnabled: false, compassEnabled: true,
            onTap: (_) { 
              if (mounted) setState(() => _selectedStation = null); 
            },
          ),
          if (_showListView) Container(color: Colors.white, child: _buildListView()),
          if (!_showListView && _selectedStation != null)
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: Builder(builder: (cardContext) {
                // Capture _selectedStation for safe usage within this builder pass
                final capturedStation = _selectedStation;

                // Additional null check for safety, though outer check should suffice
                if (capturedStation == null) {
                  return const SizedBox.shrink(); // Return empty if it became null unexpectedly
                }

                final stationId = capturedStation['station_id'] as int?;
                
                if (stationId != null && _userId != null && !_stationFavoriteStatus.containsKey(stationId) && !(_stationLoadingStatus[stationId] ?? false)){
                    WidgetsBinding.instance.addPostFrameCallback((_) { 
                      if(mounted) _fetchFavoriteStatus(stationId); 
                    });
                }
                return StationCard(
                  stationId: stationId ?? -1,
                  name: capturedStation['name'] ?? "Charging Station",
                  address: capturedStation['address'] ?? "No address",
                  viewLabel: "View Detail",
                  isFavorite: stationId != null ? (_stationFavoriteStatus[stationId] ?? false) : false,
                  isLoadingFavorite: stationId != null ? (_stationLoadingStatus[stationId] ?? false) : false,
                  onFavoriteToggle: stationId != null 
                    ? () => _toggleFavorite(stationId)
                    : () => ScaffoldMessenger.of(cardContext).showSnackBar(
                          const SnackBar(content: Text('Station ID missing or user not logged in.')),
                        ),
                  onViewPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StationView(station: capturedStation))),
                  onBookPressed: () => debugPrint("Book tapped for ${capturedStation['name']}"),
                );
              }),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [ _buildSearchRow(), const SizedBox(height: 12), _buildToggleButtons() ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final stations = _mapControllerHelper.stations;
    if (stations.isEmpty) return const Center(child: Text("Loading stations or no stations available..."));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final stationId = station['station_id'] as int?;
        if (stationId != null && _userId != null && !_stationFavoriteStatus.containsKey(stationId) && !(_stationLoadingStatus[stationId] ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) { 
            if(mounted) _fetchFavoriteStatus(stationId); 
          });
        }
        return StationCard(
          stationId: stationId ?? -1,
          name: station['name'] ?? 'Charging Station',
          address: station['address'] ?? 'No address',
          viewLabel: "View Station",
          isFavorite: stationId != null ? (_stationFavoriteStatus[stationId] ?? false) : false,
          isLoadingFavorite: stationId != null ? (_stationLoadingStatus[stationId] ?? false) : false,
          onFavoriteToggle: stationId != null 
            ? () => _toggleFavorite(stationId)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Station ID missing or user not logged in.')),
                ),
          onViewPressed: () {
            if (mounted) {
              final sId = station['station_id'] as int?;
              if (sId != null && _userId != null && !_stationFavoriteStatus.containsKey(sId) && !(_stationLoadingStatus[sId] ?? false)) {
                 _fetchFavoriteStatus(sId); 
              }
              setState(() { 
                _selectedStation = station; 
                _showListView = false; 
              });
              WidgetsBinding.instance.addPostFrameCallback((_) { 
                 if(mounted) _animateToStation(station); 
              });
            }
          },
          onBookPressed: () => debugPrint("Book button tapped for ${station['name']}"),
        );
      },
    );
  }

  Widget _buildSearchRow() { return Row(children: [Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12),decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(12),boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),blurRadius: 5,)]),child: const TextField(decoration: InputDecoration(icon: Icon(Icons.search),hintText: "Search location",border: InputBorder.none,),),),),const SizedBox(width: 10),Container(height: 48,width: 48,decoration: BoxDecoration(color: Colors.green,borderRadius: BorderRadius.circular(12),),child: const Icon(Icons.tune, color: Colors.white),),]); }
  Widget _buildToggleButtons() { return Row(children: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: !_showListView ? Colors.green : Colors.white,foregroundColor: !_showListView ? Colors.white : Colors.black,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),),onPressed: () { if (mounted) setState(() => _showListView = false); },child: const Text("Map view"),),const SizedBox(width: 8),ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _showListView ? Colors.green : Colors.white,foregroundColor: _showListView ? Colors.white : Colors.black,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),),onPressed: () { if (mounted) { setState(() { _showListView = true; _selectedStation = null; }); } },child: const Text("List view"),),]); }
}
