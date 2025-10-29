import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testing/src/presentation/pages/auth_view.dart';
import 'admin_station_service.dart';
import 'add_station_form.dart'; // Import the new form


// --- Data Model ---
class Station {
  final int stationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool hasBikeCharger; // This could potentially be derived from bikeChargerCapacity != null
  final bool hasCarCharger;  // This could potentially be derived from carChargerCapacity != null
  final String? carChargerCapacity; // New field for car charger capacity string (e.g., "60KW")
  final String? bikeChargerCapacity; // New field for bike charger capacity string (e.g., "15KW")
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Station({
    required this.stationId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.hasBikeCharger,
    required this.hasCarCharger,
    this.carChargerCapacity, // Added to constructor
    this.bikeChargerCapacity, // Added to constructor
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // The fromMap will be populated in two stages:
  // 1. Basic station data from 'charging_stations' table.
  // 2. Capacity data from 'station_charger_capacity' table (done by the service layer).
  factory Station.fromMap(Map<String, dynamic> map, {String? carCapacity, String? bikeCapacity}) {
    return Station(
      stationId: map['station_id'] as int,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      hasBikeCharger: map['has_bike_charger'] as bool? ?? false, // Keep for now
      hasCarCharger: map['has_car_charger'] as bool? ?? false, // Keep for now
      carChargerCapacity: carCapacity, // Populate with fetched capacity
      bikeChargerCapacity: bikeCapacity, // Populate with fetched capacity
      status: map['status'] as String? ?? 'unknown',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum AdminView { manage, add, edit }

class ManageStationsView extends StatefulWidget {
  final Station? stationToEdit;
  final bool isOpenedFromDetailPage;
  const ManageStationsView({super.key, this.stationToEdit, this.isOpenedFromDetailPage = false});

  @override
  State<ManageStationsView> createState() => _ManageStationsViewState();
}

class _ManageStationsViewState extends State<ManageStationsView> {
  AdminView _currentView = AdminView.manage;
  late final AdminStationService _adminStationService;
  Future<List<Station>>? _stationsFuture;
  Station? _editingStation;

  late TextEditingController _searchController;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _adminStationService = AdminStationService(Supabase.instance.client);
    _stationsFuture = _fetchStations();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);

    if (widget.stationToEdit != null) {
      _currentView = AdminView.edit;
      _editingStation = widget.stationToEdit;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text;
    });
  }

  Future<List<Station>> _fetchStations() async {
    final response = await Supabase.instance.client
        .from('charging_stations')
        .select('*, station_charger_capacity(vehicle_type, capacity_value)')
        .order('created_at', ascending: false);

    final List<Station> stations = [];
    for (final stationMap in (response as List)) {
      String? carCapacity;
      String? bikeCapacity;

      if (stationMap['station_charger_capacity'] != null) {
        final capacities = stationMap['station_charger_capacity'] as List;
        for (final capMap in capacities) {
          final type = capMap['vehicle_type'] as String?;
          final value = capMap['capacity_value'] as String?;
          if (type == 'car') {
            carCapacity = value;
          } else if (type == 'bike') {
            bikeCapacity = value;
          }
        }
      }
      stations.add(Station.fromMap(stationMap, carCapacity: carCapacity, bikeCapacity: bikeCapacity));
    }
    return stations;
  }

  void _refreshStations() {
    setState(() {
      _stationsFuture = _fetchStations();
    });
  }

  void _showFeedback(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  void _addStation(String name, String address, double latitude, double longitude, bool hasBikeCharger, bool hasCarCharger, String status, String? carChargerCapacity, String? bikeChargerCapacity) async {
    try {
      await _adminStationService.addStation(
        name: name, address: address, latitude: latitude, longitude: longitude,
        hasBikeCharger: hasBikeCharger, hasCarCharger: hasCarCharger, status: status,
        carChargerCapacity: carChargerCapacity, // Pass capacity
        bikeChargerCapacity: bikeChargerCapacity, // Pass capacity
      );
      _showFeedback('$name has been added.', false);
      _refreshStations();
      setState(() => _currentView = AdminView.manage);
    } catch (e) {
      _showFeedback('Error adding station: ${e.toString().split('.').first}', true);
    }
  }

  void _updateStation(int stationId, String name, String address, double latitude, double longitude, bool hasBikeCharger, bool hasCarCharger, String status, String? carChargerCapacity, String? bikeChargerCapacity) async {
    try {
      await _adminStationService.updateStation(
        stationId: stationId, name: name, address: address, latitude: latitude, longitude: longitude,
        hasBikeCharger: hasBikeCharger, hasCarCharger: hasCarCharger, status: status,
        carChargerCapacity: carChargerCapacity,
        bikeChargerCapacity: bikeChargerCapacity,
      );
      _showFeedback('$name has been updated.', false);
      _refreshStations();

      if (widget.isOpenedFromDetailPage) {
        // Refetch the single updated station to get all the latest data
        final updatedStationData = await Supabase.instance.client
            .from('charging_stations')
            .select('*, station_charger_capacity(vehicle_type, capacity_value)')
            .eq('station_id', stationId)
            .single();
        
        String? carCap;
        String? bikeCap;
        if (updatedStationData['station_charger_capacity'] != null) {
            final capacities = updatedStationData['station_charger_capacity'] as List;
            for (final capMap in capacities) {
                final type = capMap['vehicle_type'] as String?;
                final value = capMap['capacity_value'] as String?;
                if (type == 'car') {
                    carCap = value;
                } else if (type == 'bike') {
                    bikeCap = value;
                }
            }
        }
        final updatedStation = Station.fromMap(updatedStationData, carCapacity: carCap, bikeCapacity: bikeCap);
        Navigator.of(context).pop(updatedStation); // Pop with result
      } else {
        setState(() {
          _currentView = AdminView.manage;
          _editingStation = null;
        });
      }
    } catch (e) {
      _showFeedback('Error updating station: ${e.toString().split('.').first}', true);
    }
  }


  void _promptDeleteStation(int stationId, String stationName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Delete Station'),
          content: Text('Are you sure you want to delete $stationName?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteStation(stationId, stationName);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteStation(int stationId, String stationName) async {
    try {
      await _adminStationService.deleteStation(stationId: stationId);
      _showFeedback('$stationName has been deleted.', false);
      _refreshStations();
      if (widget.isOpenedFromDetailPage) {
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      } else {
        setState(() {
          _currentView = AdminView.manage;
          _editingStation = null;
        });
      }
    } catch (e) {
      _showFeedback('Error deleting station: ${e.toString().split('.').first}', true);
    }
  }


  Color _getStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'available': return colorScheme.primary;
      case 'offline': return colorScheme.error;
      default: return Colors.grey.shade500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available': return Icons.check_circle_outline_rounded;
      case 'offline': return Icons.power_settings_new_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String titleText = 'Manage Stations';
    if (_currentView == AdminView.add) {
      titleText = 'Add New Station';
    } else if (_currentView == AdminView.edit && _editingStation != null) {
      titleText = 'Edit: ${_editingStation!.name}';
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(
        title: Text(titleText, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        leading: (_currentView == AdminView.edit || _currentView == AdminView.add)
            ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
             if (widget.isOpenedFromDetailPage) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _currentView = AdminView.manage;
                  _editingStation = null;
                  _searchController.clear();
                });
              }
          },
        )
            : null,
        actions: [
          if (_currentView == AdminView.manage) ...[
            IconButton(
              icon: const Icon(Icons.add_location_alt_outlined),
              tooltip: 'New Station',
              onPressed: () => setState(() => _currentView = AdminView.add),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => AuthView(onClose: () {}, onViewModeChange: (bool isSignup) {})),
                      (route) => false,
                );
              },
            ),
          ]
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case AdminView.manage:
        return _buildManageView(key: const ValueKey('manage'));
      case AdminView.add:
        return AddStationForm(
          key: const ValueKey('add'),
          onSave: (name, address, lat, long, hasBike, hasCar, status, carCap, bikeCap) {
            _addStation(name, address, lat, long, hasBike, hasCar, status, carCap, bikeCap);
          },
          onCancel: () => setState(() => _currentView = AdminView.manage),
        );
      case AdminView.edit:
        if (_editingStation != null) {
          return AddStationForm(
            key: ValueKey('edit_form_${_editingStation!.stationId}'),
            stationToEdit: _editingStation,
            onSave: (name, address, lat, long, hasBike, hasCar, status, carCap, bikeCap) {
              _updateStation(_editingStation!.stationId, name, address, lat, long, hasBike, hasCar, status, carCap, bikeCap);
            },
            onCancel: () {
              if (widget.isOpenedFromDetailPage) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _currentView = AdminView.manage;
                  _editingStation = null;
                });
              }
            },
            onDelete: _promptDeleteStation,
          );
        }
        return _buildManageView(key: const ValueKey('manage_fallback'));
    }
  }

  Widget _buildManageView({Key? key}) {
    final theme = Theme.of(context);
    return Column(
      key: key,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stations by name or address...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary.withOpacity(0.8)),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear_rounded, color: Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Station>>(
            future: _stationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _stationsFuture == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text('Could not load stations.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                      Text('${snapshot.error}', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(icon: const Icon(Icons.refresh_rounded), label: const Text("Retry"), onPressed: _refreshStations, style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary))
                    ]),
                  ),
                );
              }

              final allStations = snapshot.data ?? [];
              final List<Station> filteredStations;
              if (_searchTerm.isEmpty) {
                filteredStations = allStations;
              } else {
                filteredStations = allStations.where((station) {
                  final searchTermLower = _searchTerm.toLowerCase();
                  return station.name.toLowerCase().contains(searchTermLower) ||
                      station.address.toLowerCase().contains(searchTermLower);
                }).toList();
              }

              if (allStations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.explore_off_rounded, color: Colors.grey[400], size: 72),
                      const SizedBox(height: 20),
                      Text('No Stations Yet', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Text('Start by adding a new charging station.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                    ]),
                  ),
                );
              }

              if (filteredStations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search_off_rounded, color: Colors.grey[400], size: 72),
                      const SizedBox(height: 20),
                      Text('No Results Found', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Text('Try a different search term or clear the search to see all stations.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                    ]),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted bottom padding
                itemCount: filteredStations.length,
                itemBuilder: (context, index) => _buildStationListItem(filteredStations[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationListItem(Station station) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(context, station.status);
    final statusIcon = _getStatusIcon(station.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 0.5,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () => setState(() { _editingStation = station; _currentView = AdminView.edit; }),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      station.status[0].toUpperCase() + station.status.substring(1),
                      style: theme.textTheme.labelLarge?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_rounded, color: Colors.grey[400], size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(station.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(station.address, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (station.hasCarCharger) ...[
                      Icon(Icons.directions_car_filled_rounded, size: 18, color: Colors.blueGrey[600]),
                      const SizedBox(width: 4),
                      Text(station.carChargerCapacity ?? 'Car', style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[700])), // Display capacity
                      if (station.hasBikeCharger || (station.bikeChargerCapacity != null && station.bikeChargerCapacity!.isNotEmpty)) const SizedBox(width: 12), // Adjusted condition
                    ],
                    if (station.hasBikeCharger) ...[
                      Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.blueGrey[600]),
                      const SizedBox(width: 4),
                      Text(station.bikeChargerCapacity ?? 'Bike', style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[700])), // Display capacity
                    ],
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
