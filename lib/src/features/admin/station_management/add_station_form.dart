import 'package:flutter/material.dart';
import 'manage_stations_view.dart'; // For Station class

class AddStationForm extends StatefulWidget {
  final Function(String name, String address, double latitude, double longitude, bool hasBikeCharger, bool hasCarCharger, String status, String? carChargerCapacity, String? bikeChargerCapacity) onSave;
  final VoidCallback onCancel;
  final Station? stationToEdit;
  final Function(int stationId, String stationName)? onDelete;

  const AddStationForm({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.stationToEdit,
    this.onDelete,
  });

  @override
  State<AddStationForm> createState() => _AddStationFormState();
}

class _AddStationFormState extends State<AddStationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _carCapacityController; // New
  late TextEditingController _bikeCapacityController; // New
  String? _selectedStatus;
  bool _hasBikeCharger = false;
  bool _hasCarCharger = false;
  bool get _isEditMode => widget.stationToEdit != null;

  @override
  void initState() {
    super.initState();
    final station = widget.stationToEdit;
    _nameController = TextEditingController(text: station?.name);
    _addressController = TextEditingController(text: station?.address);
    _latitudeController = TextEditingController(text: station?.latitude.toString());
    _longitudeController = TextEditingController(text: station?.longitude.toString());
    _carCapacityController = TextEditingController(text: station?.carChargerCapacity); // New
    _bikeCapacityController = TextEditingController(text: station?.bikeChargerCapacity); // New
    _selectedStatus = station?.status;
    if (_selectedStatus != null && !['available', 'offline'].contains(_selectedStatus)) {
      _selectedStatus = 'available';
    }
    _hasBikeCharger = station?.hasBikeCharger ?? false;
    _hasCarCharger = station?.hasCarCharger ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _carCapacityController.dispose(); // New
    _bikeCapacityController.dispose(); // New
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_hasBikeCharger && !_hasCarCharger) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one charger type.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        return;
      }
      if (_selectedStatus == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a status.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        return;
      }
      widget.onSave(
        _nameController.text.trim(),
        _addressController.text.trim(),
        double.parse(_latitudeController.text.trim()),
        double.parse(_longitudeController.text.trim()),
        _hasBikeCharger,
        _hasCarCharger,
        _selectedStatus!,
        _hasCarCharger ? _carCapacityController.text.trim() : null, // Pass car capacity
        _hasBikeCharger ? _bikeCapacityController.text.trim() : null, // Pass bike capacity
      );
    }
  }

  InputDecoration _inputDecoration(String labelText, ThemeData theme) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom > 0 ? mediaQuery.viewInsets.bottom + 10 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('STATION DETAILS', theme),
            TextFormField(controller: _nameController, decoration: _inputDecoration('Station Name', theme), validator: (v) => v == null || v.trim().isEmpty ? 'Station name is required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _addressController, decoration: _inputDecoration('Address', theme), maxLines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null),

            _buildSectionHeader('LOCATION COORDINATES', theme),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _latitudeController, decoration: _inputDecoration('Latitude', theme), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), validator: (v) { if(v==null||v.trim().isEmpty)return'Required';final n=double.tryParse(v.trim());if(n==null)return'Invalid format';if(n<-90||n>90)return'Range: -90 to 90';return null;})),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _longitudeController, decoration: _inputDecoration('Longitude', theme), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), validator: (v) { if(v==null||v.trim().isEmpty)return'Required';final n=double.tryParse(v.trim());if(n==null)return'Invalid format';if(n<-180||n>180)return'Range: -180 to 180';return null;})),
              ],
            ),

            _buildSectionHeader('FACILITIES & STATUS', theme),
            DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: _inputDecoration('Status', theme),
                items: ['available', 'offline'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase()+s.substring(1)))).toList(),
                onChanged: (v)=>setState(()=>_selectedStatus=v),
                validator: (v)=>v==null?'Status is required':null
            ),
            const SizedBox(height: 16),
            Text('Charger Types:', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey[700])),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(children: [Checkbox(value: _hasCarCharger, onChanged: (v)=>setState(()=>_hasCarCharger=v!), activeColor: colorScheme.primary), const Text('Car Charger')]),
                ),
                Expanded(
                  child: Row(children: [Checkbox(value: _hasBikeCharger, onChanged: (v)=>setState(()=>_hasBikeCharger=v!), activeColor: colorScheme.primary), const Text('Bike Charger')]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_hasCarCharger)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: _carCapacityController,
                  decoration: _inputDecoration('Car Charger Capacity (e.g., 60KW)', theme),
                  validator: (v) => _hasCarCharger && (v == null || v.trim().isEmpty) ? 'Car capacity is required' : null,
                ),
              ),
            if (_hasBikeCharger)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: _bikeCapacityController,
                  decoration: _inputDecoration('Bike Charger Capacity (e.g., 15KW)', theme),
                  validator: (v) => _hasBikeCharger && (v == null || v.trim().isEmpty) ? 'Bike capacity is required' : null,
                ),
              ),
            
            const SizedBox(height: 16), // Adjusted spacing if both capacity fields are shown

            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
              child: Text(_isEditMode ? 'SAVE CHANGES' : 'ADD STATION', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),

            if (_isEditMode && widget.onDelete != null)
              OutlinedButton.icon(
                  icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 20),
                  label: Text('Delete Station', style: TextStyle(color: colorScheme.error)),
                  onPressed: () {
                    widget.onDelete!(widget.stationToEdit!.stationId, widget.stationToEdit!.name);
                  },
                  style: OutlinedButton.styleFrom(side: BorderSide(color: colorScheme.error.withOpacity(0.7)), padding: const EdgeInsets.symmetric(vertical: 14.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))
              ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: widget.onCancel,
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
            ),
            const SizedBox(height: 16), 
          ],
        ),
      ),
    );
  }
}
