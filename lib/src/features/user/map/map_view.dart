import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:testing/main.dart'; // For appRouteObserver
import '../../admin/station_management/manage_stations_view.dart'; // For Station model
import '../favorites/favorites_service.dart';
import 'map_controller.dart';
import 'map_service.dart';
import 'station_card.dart';
import '../station/station_view.dart';
import '../booking/booking_view.dart';

class UserMapView extends StatefulWidget {
  final bool isAdmin; 
  const UserMapView({super.key, this.isAdmin = false});

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
  Map<String, dynamic>? _selectedStationDataMap;

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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint("UserMapView: didPopNext - refreshing all views.");
    _refreshStationsAndFavorites();
    super.didPopNext();
  }
  
  void _refreshStationsAndFavorites() {
    _mapControllerHelper.loadStations(_currentPosition, onStationSelectedCallback).then((_) {
      if (mounted) {
        setState(() {
          _refreshVisibleFavoriteStatuses();
        });
      }
    });
  }


  // Centralized callback for when a station is selected from ANY source.
  void onStationSelectedCallback(Map<String, dynamic> stationDataMap) {
    if (mounted) {
      final Station? station = stationDataMap['station'] as Station?;
      if (station != null &&
          _userId != null &&
          !widget.isAdmin &&
          !_stationFavoriteStatus.containsKey(station.stationId) &&
          !(_stationLoadingStatus[station.stationId] ?? false)) {
        _fetchFavoriteStatus(station.stationId);
      }
      
      // Set the state to show the map and the selected station card
      setState(() {
        _selectedStationDataMap = stationDataMap;
        _showListView = false;
      });

      // Defer animation until after the build phase is complete.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animateToStation(stationDataMap);
        }
      });
    }
  }

  void _refreshVisibleFavoriteStatuses() {
    if (!mounted || widget.isAdmin) return;
    if (!_showListView && _selectedStationDataMap != null) {
      final Station? station = _selectedStationDataMap!['station'] as Station?;
      if (station != null) {
        _fetchFavoriteStatus(station.stationId);
      }
    }
    if (_showListView) {
      _stationFavoriteStatus.clear();
      _stationLoadingStatus.clear();
    }
    setState(() {}); 
  }

  Future<void> _fetchFavoriteStatus(int stationId) async {
    if (_userId == null || (_stationLoadingStatus[stationId] ?? false) || widget.isAdmin) return;
    if (mounted) setState(() => _stationLoadingStatus[stationId] = true);
    try {
      final isFav = await _favoritesService.isFavorite(_userId!, stationId);
      if (mounted) setState(() => _stationFavoriteStatus[stationId] = isFav);
    } catch (e) {
      debugPrint("Error fetching fav status for $stationId: $e");
    } finally {
      if (mounted) setState(() => _stationLoadingStatus[stationId] = false);
    }
  }

  Future<void> _toggleFavorite(int stationId) async {
    if (_userId == null || (_stationLoadingStatus[stationId] ?? false) || widget.isAdmin) return;
    if (mounted) setState(() => _stationLoadingStatus[stationId] = true);
    bool currentStatus = _stationFavoriteStatus[stationId] ?? false;
    try {
      if (currentStatus) {
        await _favoritesService.removeFavorite(_userId!, stationId);
      } else {
        await _favoritesService.addFavorite(_userId!, stationId);
      }
      if (mounted) {
        setState(() => _stationFavoriteStatus[stationId] = !currentStatus);
      }
    } catch (e) {
      debugPrint("Error toggling fav for $stationId: $e");
    } finally {
      if (mounted) setState(() => _stationLoadingStatus[stationId] = false);
    }
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    if (mounted) setState(() => _isLoading = false);
    _loadMapStyle();
    await _mapControllerHelper.loadStations(_currentPosition, onStationSelectedCallback);
    if (mounted) setState(() {});
  }

  Future<void> _animateToStation(Map<String, dynamic> stationDataMap) async {
    final Station? station = stationDataMap['station'] as Station?;
    if (station == null || _mapController == null) return;
    final LatLng stationPosition = LatLng(station.latitude, station.longitude);
    try {
      await _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: stationPosition, zoom: 17)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error animating to station: ${e.toString()}')),
        );
      }
      debugPrint("Error animating to station: $e");
    }
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.txt').catchError((_) => null);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _currentPosition = LatLng(p.latitude, p.longitude));
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Visibility(
                  visible: !_showListView,
                  maintainState: true,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: _currentPosition ?? const LatLng(19.0760, 72.8777),
                        zoom: _currentPosition != null ? 16 : 12),
                    onMapCreated: (GoogleMapController controller) async {
                      _mapController = controller;
                      if (_mapStyle != null) controller.setMapStyle(_mapStyle);
                    },
                    markers: _mapControllerHelper.markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    onTap: (_) {
                      if (mounted) setState(() => _selectedStationDataMap = null);
                    },
                  ),
                ),
                if (_showListView)
                  Container(color: Colors.white, child: _buildListView()),

                // Search and Toggle buttons, always visible
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(children: [
                      _buildSearchRow(),
                      const SizedBox(height: 12),
                      _buildToggleButtons()
                    ]),
                  ),
                ),

                // Non-admin specific UI (gradient and floating card)
                if (!widget.isAdmin && !_showListView && _selectedStationDataMap != null) ...[
                  IgnorePointer(
                    child: Container(
                      height: 160.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).scaffoldBackgroundColor,
                            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Builder(builder: (cardContext) {
                        final station = _selectedStationDataMap!['station'] as Station?;
                        if (station == null) return const SizedBox.shrink();
                        return StationCard(
                          station: station,
                          stationId: station.stationId,
                          name: station.name,
                          address: station.address,
                          distanceKm: _selectedStationDataMap!['distance'] as double?,
                          viewLabel: "View Detail",
                          isFavorite: _stationFavoriteStatus[station.stationId] ?? false,
                          isLoadingFavorite: _stationLoadingStatus[station.stationId] ?? false,
                          onFavoriteToggle: () => _toggleFavorite(station.stationId),
                          onViewPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => StationView(
                                      station: station,
                                      isAdmin: widget.isAdmin,
                                    )));
                          },
                          onBookPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => BookingView(stationId: station.stationId)));
                          },
                          isAdmin: widget.isAdmin,
                        );
                      }),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildListView() {
    final stationsDataList = _mapControllerHelper.stations;
    if (stationsDataList.isEmpty) {
      return const Center(child: Text("No stations available..."));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
      itemCount: stationsDataList.length,
      itemBuilder: (context, index) {
        final stationDataMap = stationsDataList[index];
        final Station? station = stationDataMap['station'] as Station?;
        if (station == null) return const SizedBox.shrink();

        return StationCard(
          station: station, // Pass the full station object here
          stationId: station.stationId,
          name: station.name,
          address: station.address,
          distanceKm: stationDataMap['distance'] as double?,
          viewLabel: "View Station",
          isFavorite: _stationFavoriteStatus[station.stationId] ?? false,
          isLoadingFavorite: _stationLoadingStatus[station.stationId] ?? false,
          onFavoriteToggle: () => _toggleFavorite(station.stationId),
          onViewPressed: () {
            if (widget.isAdmin) {
               Navigator.push(context, MaterialPageRoute(builder: (_) => StationView(station: station, isAdmin: true))).then((_) => _refreshStationsAndFavorites());
            } else {
              onStationSelectedCallback(stationDataMap);
            }
          },
          onBookPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => BookingView(stationId: station.stationId)));
          },
          isAdmin: widget.isAdmin,
        );
      },
    );
  }

  Widget _buildSearchRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (stationDataMap) => (stationDataMap['station'] as Station?)?.name ?? '',
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable.empty();
              final query = textEditingValue.text.toLowerCase();
              return _mapControllerHelper.stations.where((s) {
                final station = s['station'] as Station?;
                return station?.name.toLowerCase().contains(query) ?? false;
              });
            },
            onSelected: (selection) {
              FocusScope.of(context).unfocus();
              onStationSelectedCallback(selection);
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(30.0),
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: textEditingController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => textEditingController.clear())
                        : null,
                    hintText: "Search stations...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final stationDataMap = options.elementAt(index);
                        final station = stationDataMap['station'] as Station?;
                        if (station == null) return const SizedBox.shrink();
                        return ListTile(
                          leading: const Icon(Icons.ev_station),
                          title: Text(station.name),
                          onTap: () => onSelected(stationDataMap),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Row(children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: !_showListView ? Colors.green : Colors.white,
          foregroundColor: !_showListView ? Colors.white : Colors.black,
        ),
        onPressed: () => setState(() => _showListView = false),
        child: const Text("Map"),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _showListView ? Colors.green : Colors.white,
          foregroundColor: _showListView ? Colors.white : Colors.black,
        ),
        onPressed: () => setState(() {
          _showListView = true;
          _selectedStationDataMap = null;
        }),
        child: const Text("List"),
      ),
    ]);
  }
}
