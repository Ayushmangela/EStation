import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

// Corrected import to use package notation
import 'package:testing/main.dart';

import '../../admin/station_management/manage_stations_view.dart';
import '../favorites/favorites_service.dart';
import 'map_controller.dart';
import 'map_service.dart';
import 'station_card.dart';
import '../station/station_view.dart';
import '../booking/booking_view.dart'; // Added import for BookingView

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

  void onStationSelectedCallback(Map<String, dynamic> station) {
    if (mounted) {
      final stationId = station['station_id'] as int?;
      if (stationId != null &&
          _userId != null &&
          !_stationFavoriteStatus.containsKey(stationId) &&
          !(_stationLoadingStatus[stationId] ?? false)) {
        _fetchFavoriteStatus(stationId);
      }
      setState(() {
        _selectedStation = station;
        _showListView = false;
      });
      _animateToStation(station);
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error checking favorite: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _stationLoadingStatus[stationId] = false);
    }
  }

  Future<void> _toggleFavorite(int stationId) async {
    if (_userId == null || (_stationLoadingStatus[stationId] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login or station ID missing/loading.')));
      return;
    }
    if (mounted) setState(() => _stationLoadingStatus[stationId] = true);
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      debugPrint("Error toggling fav for $stationId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating favorite: ${e.toString()}")));
      }
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

  Future<void> _animateToStation(Map<String, dynamic> station) async {
    final LatLng? stationPosition = station['position'] as LatLng?;
    try {
      if (_mapController != null && stationPosition != null) {
        await _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: stationPosition, zoom: 17)));
      }
    } catch (e) {
      debugPrint("Error animating to station: $e");
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.txt');
    } catch (e) {
      debugPrint("Error loading map style: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services disabled.");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied.");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission denied forever.");
        return;
      }
      Position p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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
                // Layer 1: Background (Map or List View)
                if (_showListView)
                  Container(color: Colors.white, child: _buildListView())
                else
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: _currentPosition ?? const LatLng(19.0760, 72.8777),
                        zoom: _currentPosition != null ? 16 : 12),
                    onMapCreated: (GoogleMapController controller) async {
                      _mapController = controller;
                      if (_mapStyle != null) {
                        try {
                          await controller.setMapStyle(_mapStyle);
                        } catch (e) {
                          debugPrint("Error setting map style: $e");
                        }
                      }
                    },
                    markers: _mapControllerHelper.markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    onTap: (_) {
                      if (mounted) setState(() => _selectedStation = null);
                    },
                  ),

                // Layer 2: Gradient on top of background
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

                // Layer 3: Conditional UI on top of gradient
                if (!_showListView && _selectedStation != null)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Builder(builder: (cardContext) {
                      final capturedStation = _selectedStation;
                      if (capturedStation == null) {
                        return const SizedBox.shrink();
                      }
                      final stationId = capturedStation['station_id'] as int?;

                      if (stationId != null &&
                          _userId != null &&
                          !_stationFavoriteStatus.containsKey(stationId) &&
                          !(_stationLoadingStatus[stationId] ?? false)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _fetchFavoriteStatus(stationId);
                        });
                      }
                      return StationCard(
                        stationId: stationId ?? -1,
                        name: capturedStation['name'] ?? "Charging Station",
                        address: capturedStation['address'] ?? "No address",
                        distanceKm: capturedStation['distance'] as double?,
                        viewLabel: "View Detail",
                        isFavorite: stationId != null
                            ? (_stationFavoriteStatus[stationId] ?? false)
                            : false,
                        isLoadingFavorite: stationId != null
                            ? (_stationLoadingStatus[stationId] ?? false)
                            : false,
                        onFavoriteToggle: stationId != null
                            ? () => _toggleFavorite(stationId)
                            : () => ScaffoldMessenger.of(cardContext).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Station ID missing or user not logged in.')),
                                ),
                        onViewPressed: () {
                          final station = Station(
                            stationId: capturedStation['station_id'] as int,
                            name: capturedStation['name'] as String,
                            address: capturedStation['address'] as String,
                            latitude: (capturedStation['latitude'] as num).toDouble(),
                            longitude: (capturedStation['longitude'] as num).toDouble(),
                            operator: capturedStation['operator'] as String?,
                            hasBikeCharger: capturedStation['has_bike_charger'] as bool,
                            hasCarCharger: capturedStation['has_car_charger'] as bool,
                            status: capturedStation['status'] as String,
                            createdAt: DateTime.parse(capturedStation['created_at'] as String),
                            updatedAt: DateTime.parse(capturedStation['updated_at'] as String),
                          );
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => StationView(station: station)));
                        },
                        onBookPressed: () {
                          if (stationId != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => BookingView(stationId: stationId)));
                          } else {
                            ScaffoldMessenger.of(cardContext).showSnackBar(
                              const SnackBar(content: Text('Station ID is not available.')),
                            );
                          }
                        },
                      );
                    }),
                  ),

                // Layer 4: Topmost UI
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
              ],
            ),
    );
  }

  Widget _buildListView() {
    final stations = _mapControllerHelper.stations;
    if (stations.isEmpty) {
      return const Center(child: Text("Loading stations or no stations available..."));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final stationId = station['station_id'] as int?;
        if (stationId != null &&
            _userId != null &&
            !_stationFavoriteStatus.containsKey(stationId) &&
            !(_stationLoadingStatus[stationId] ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fetchFavoriteStatus(stationId);
          });
        }
        return StationCard(
          stationId: stationId ?? -1,
          name: station['name'] ?? 'Charging Station',
          address: station['address'] ?? 'No address',
          distanceKm: station['distance'] as double?,
          viewLabel: "View Station",
          isFavorite:
              stationId != null ? (_stationFavoriteStatus[stationId] ?? false) : false,
          isLoadingFavorite:
              stationId != null ? (_stationLoadingStatus[stationId] ?? false) : false,
          onFavoriteToggle: stationId != null
              ? () => _toggleFavorite(stationId)
              : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Station ID missing or user not logged in.')),
                  ),
          onViewPressed: () {
            onStationSelectedCallback(station);
          },
          onBookPressed: () {
            if (stationId != null) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => BookingView(stationId: stationId)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Station ID is not available.')),
              );
            }
          },
        );
      },
    );
  }

  // ## UI ENHANCEMENT: MODERN SEARCH BAR AND SUGGESTIONS ##
  Widget _buildSearchRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (station) => station['name'] as String,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              return _mapControllerHelper.stations.where((station) {
                final String name = (station['name'] as String?)?.toLowerCase() ?? '';
                final String address = (station['address'] as String?)?.toLowerCase() ?? '';
                final String query = textEditingValue.text.toLowerCase();
                return name.contains(query) || address.contains(query);
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
                shadowColor: Colors.black.withOpacity(0.2),
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: textEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => textEditingController.clear(),
                          )
                        : null,
                    hintText: "Search by name or address...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Colors.green, width: 1.5),
                    ),
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              if (options.isEmpty) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No stations found.'),
                    ),
                  ),
                );
              }

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72, endIndent: 16),
                      itemBuilder: (BuildContext context, int index) {
                        final station = options.elementAt(index);
                        final distance = station['distance'] as double?;
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.ev_station_rounded),
                          ),
                          title: Text(station['name'] ?? 'Unknown Station',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              station['address'] ?? 'No address available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          trailing: distance != null
                              ? Text(
                                  '${distance.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                )
                              : null,
                          onTap: () => onSelected(station),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(30.0),
          shadowColor: Colors.black.withOpacity(0.2),
          child: InkWell(
            borderRadius: BorderRadius.circular(30.0),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Filter functionality not yet implemented.')),
              );
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.green),
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          if (mounted) setState(() => _showListView = false);
        },
        child: const Text("Map view"),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _showListView ? Colors.green : Colors.white,
          foregroundColor: _showListView ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          if (mounted) {
            setState(() {
              _showListView = true;
              _selectedStation = null;
            });
          }
        },
        child: const Text("List view"),
      ),
    ]);
  }
}
