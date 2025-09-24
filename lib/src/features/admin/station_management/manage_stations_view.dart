import 'package:flutter/material.dart';
import 'dart:math'; // Used for generating a random ID

// --- Data Model ---
class Station {
  final String id;
  final String name;
  final String address;
  final String status;
  final double latitude;
  final double longitude;
  final List<String> chargers;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.chargers,
  });
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

  // Static list of stations for demo purposes
  final List<Station> _stations = [
    Station(
      id: 'stn_001',
      name: 'GreenCharge Hub Mumbai',
      address: 'BKC, Bandra East, Mumbai, Maharashtra 400051',
      status: 'Available',
      latitude: 19.0669,
      longitude: 72.8683,
      chargers: ['Car Charger', 'Bike Charger'],
    ),
    Station(
      id: 'stn_002',
      name: 'PowerUp Andheri',
      address: 'Lokhandwala Complex, Andheri West, Mumbai',
      status: 'Available',
      latitude: 19.1333,
      longitude: 72.8273,
      chargers: ['Car Charger'],
    ),
    Station(
      id: 'stn_003',
      name: 'EV Point South Bombay',
      address: 'Near Gateway of India, Colaba, Mumbai',
      status: 'Offline',
      latitude: 18.9220,
      longitude: 72.8347,
      chargers: ['Bike Charger'],
    ),
  ];

  // Callback function to add a new station to the list
  void _addStation(Station station) {
    setState(() {
      _stations.add(station);
      _currentView = AdminView.manage; // Switch back to the manage view
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${station.name} has been added.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // --- Helper function to get theme-aware status colors ---
  Color _getStatusColor(BuildContext context, String status) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    switch (status) {
      case 'Available':
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
            onPressed: () {},
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

  // --- Widgets ---
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
    return ListView.builder(
      key: const ValueKey('manage_list'),
      itemCount: _stations.length,
      itemBuilder: (context, index) {
        final station = _stations[index];
        return _buildStationListItem(station);
      },
    );
  }

  Widget _buildStationListItem(Station station) {
    final statusColor = _getStatusColor(context, station.status);
    final theme = Theme.of(context);
    final IconData statusIcon =
    station.status == 'Available' ? Icons.check_circle : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => StationDetailView(station: station),
          ));
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

  /// ✅ UPDATED: The build method for the add view now returns a dedicated
  /// stateful widget for the form, passing the `_addStation` callback.
  Widget _buildAddView() {
    return _AddStationForm(
      key: const ValueKey('add_form'),
      onAddStation: _addStation,
    );
  }
}


/// ✅ NEW: A dedicated stateful widget to manage the "Add Station" form.
class _AddStationForm extends StatefulWidget {
  final Function(Station) onAddStation;

  const _AddStationForm({super.key, required this.onAddStation});

  @override
  State<_AddStationForm> createState() => _AddStationFormState();
}

class _AddStationFormState extends State<_AddStationForm> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  // Form state variables
  String? _selectedStatus;
  final List<String> _allChargerTypes = ['Car Charger', 'Bike Charger'];
  final Set<String> _selectedChargers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // Validate all form fields
    if (_formKey.currentState!.validate()) {
      if (_selectedChargers.isEmpty) {
        // Show an error if no charger type is selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one charger type.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create a new Station object from the form data
      final newStation = Station(
        id: 'stn_${Random().nextInt(1000)}', // Generate a random ID for demo
        name: _nameController.text,
        address: _addressController.text,
        status: _selectedStatus!,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        chargers: _selectedChargers.toList(),
      );

      // Use the callback to pass the new station to the parent widget
      widget.onAddStation(newStation);
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
            // --- Basic Info Section ---
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Location Section ---
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

            // --- Station Properties Section ---
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
                      items: ['Available', 'Offline']
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
                    Wrap(
                      spacing: 8.0,
                      children: _allChargerTypes.map((charger) {
                        final isSelected = _selectedChargers.contains(charger);
                        return FilterChip(
                          label: Text(charger),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedChargers.add(charger);
                              } else {
                                _selectedChargers.remove(charger);
                              }
                            });
                          },
                        );
                      }).toList(),
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
          ],
        ),
      ),
    );
  }

  // Helper for section titles, similar to StationDetailView
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

// --- Station Detail Screen ---
class StationDetailView extends StatelessWidget {
  final Station station;

  const StationDetailView({super.key, required this.station});

  Color _getStatusColor(BuildContext context, String status) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    switch (status) {
      case 'Available':
        return isLight ? Colors.green.shade700 : Colors.greenAccent;
      default: // Offline
        return isLight ? Colors.red.shade700 : Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            station.address,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Station Details'),
            Card(
              child: Column(
                children: [
                  _buildDetailRow(
                      context, Icons.power, 'Status', station.status,
                      valueColor: _getStatusColor(context, station.status)),
                  _buildDetailRow(context, Icons.map_outlined, 'Coordinates',
                      '${station.latitude}, ${station.longitude}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Charger Types'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: (station.chargers ?? [])
                      .map((type) => Chip(
                    avatar: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                            type == 'Car Charger'
                                ? Icons.directions_car
                                : Icons.two_wheeler,
                            size: 16,
                            color: theme.colorScheme.onPrimary)),
                    label: Text(
                      type,
                    ),
                  ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.map,
                          size: 50, color: Colors.grey[600]),
                    ),
                  ),
                  ListTile(
                    title: const Text('Location on Map'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.textTheme.bodySmall?.color),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: valueColor ?? theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}