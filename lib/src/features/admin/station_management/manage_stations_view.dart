import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testing/src/presentation/pages/auth_view.dart';
import 'admin_station_service.dart';

// --- Data Model ---
class Station {
  final int stationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? operator;
  final bool hasBikeCharger;
  final bool hasCarCharger;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Station({
    required this.stationId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.operator,
    required this.hasBikeCharger,
    required this.hasCarCharger,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      stationId: map['station_id'] as int,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      operator: map['operator'] as String?,
      hasBikeCharger: map['has_bike_charger'] as bool,
      hasCarCharger: map['has_car_charger'] as bool,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

// Enum to manage which view is currently shown on the dashboard
enum AdminView { manage, add }

// --- Main Dashboard Widget ---
class ManageStationsView extends StatefulWidget {
  const ManageStationsView({super.key});

  @override
  State<ManageStationsView> createState() => _ManageStationsViewState();
}

class _ManageStationsViewState extends State<ManageStationsView> {
  AdminView _currentView = AdminView.manage;
  late final AdminStationService _adminStationService;
  Future<List<Station>>? _stationsFuture;

  @override
  void initState() {
    super.initState();
    _adminStationService = AdminStationService(Supabase.instance.client);
    _stationsFuture = _fetchStations();
  }

  Future<List<Station>> _fetchStations() async {
    final response = await Supabase.instance.client.from('charging_stations').select();
    return (response as List).map((map) => Station.fromMap(map)).toList();
  }

  void _addStation(
    String name,
    String address,
    double latitude,
    double longitude,
    String? operator,
    bool hasBikeCharger,
    bool hasCarCharger,
    String status,
  ) async {
    try {
      await _adminStationService.addStation(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        operator: operator,
        hasBikeCharger: hasBikeCharger,
        hasCarCharger: hasCarCharger,
        status: status,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name has been added.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _stationsFuture = _fetchStations();
        _currentView = AdminView.manage;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding station: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    switch (status) {
      case 'available':
        return isLight ? Colors.green.shade700 : Colors.greenAccent;
      default: // Offline
        return isLight ? Colors.red.shade700 : Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => AuthView(
                  onClose: () {},
                  onViewModeChange: (bool isSignup) {},
                )),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSegmentedControl(),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentView == AdminView.manage
                    ? _buildManageView()
                    : _buildAddView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade200
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              'Manage Stations',
              AdminView.manage,
              Icons.ev_station,
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              'Add New Station',
              AdminView.add,
              Icons.add_location_alt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String text, AdminView view, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _currentView == view;

    final Color? backgroundColor =
    isSelected ? theme.colorScheme.primary : Colors.transparent;
    final Color contentColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.textTheme.bodyLarge!.color!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = view;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: contentColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageView() {
    return FutureBuilder<List<Station>>(
      future: _stationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No stations found.'));
        }

        final stations = snapshot.data!;
        return ListView.builder(
          key: const ValueKey('manage_list'),
          itemCount: stations.length,
          itemBuilder: (context, index) {
            final station = stations[index];
            return _buildStationListItem(station);
          },
        );
      },
    );
  }

  Widget _buildStationListItem(Station station) {
    final statusColor = _getStatusColor(context, station.status);
    final theme = Theme.of(context);
    final IconData statusIcon =
    station.status == 'available' ? Icons.check_circle : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigator.of(context).push(MaterialPageRoute(
          //   builder: (context) => StationDetailView(station: station),
          // ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.ev_station,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.address,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(statusIcon, color: statusColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddView() {
    return _AddStationForm(
      key: const ValueKey('add_form'),
      onAddStation: _addStation,
    );
  }
}

class _AddStationForm extends StatefulWidget {
  final Function(
    String name,
    String address,
    double latitude,
    double longitude,
    String? operator,
    bool hasBikeCharger,
    bool hasCarCharger,
    String status,
  ) onAddStation;

  const _AddStationForm({super.key, required this.onAddStation});

  @override
  State<_AddStationForm> createState() => _AddStationFormState();
}

class _AddStationFormState extends State<_AddStationForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _operatorController;

  String? _selectedStatus;
  bool _hasBikeCharger = false;
  bool _hasCarCharger = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _operatorController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _operatorController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_hasBikeCharger && !_hasCarCharger) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one charger type.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onAddStation(
        _nameController.text,
        _addressController.text,
        double.parse(_latitudeController.text),
        double.parse(_longitudeController.text),
        _operatorController.text,
        _hasBikeCharger,
        _hasCarCharger,
        _selectedStatus!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            Card(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                      const InputDecoration(labelText: 'Station Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a name'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter an address'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _operatorController,
                      decoration: const InputDecoration(labelText: 'Operator'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter an operator'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Location (Coordinates)'),
            Card(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration:
                        const InputDecoration(labelText: 'Longitude'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Station Properties'),
            Card(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['available', 'offline']
                          .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Please select a status' : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Charger Types',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasBikeCharger,
                          onChanged: (value) {
                            setState(() {
                              _hasBikeCharger = value!;
                            });
                          },
                        ),
                        const Text('Bike Charger'),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: _hasCarCharger,
                          onChanged: (value) {
                            setState(() {
                              _hasCarCharger = value!;
                            });
                          },
                        ),
                        const Text('Car Charger'),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Station'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 80), // Added padding at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}