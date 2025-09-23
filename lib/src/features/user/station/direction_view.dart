import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DirectionView extends StatefulWidget {
  final LatLng stationPosition;
  final String stationName;

  const DirectionView({
    super.key,
    required this.stationPosition,
    required this.stationName,
  });

  @override
  State<DirectionView> createState() => _DirectionViewState();
}

class _DirectionViewState extends State<DirectionView> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;

  String? _mapStyle;
  BitmapDescriptor? _stationMarkerIcon;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getNavigationData();
    await _loadMapStyle();
    await _loadMarkerIcons();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getNavigationData() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await _getCurrentLocation();

    if (_currentPosition != null) {
      _setMarkers();
      await _createPolylines();
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location services are disabled. Please enable the services')));
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
      }
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.txt');
    } catch (e) {
      debugPrint("Error loading map style: $e");
    }
  }

  Future<void> _loadMarkerIcons() async {
    try {
      _stationMarkerIcon = await _resizeAndLoadMarker('assets/StationMap.png', 110, 110);
    } catch (e) {
      debugPrint('Error loading station marker icon: $e');
    }
  }

  Future<BitmapDescriptor> _resizeAndLoadMarker(String assetPath, int width, int height) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;

    final ByteData? byteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _setMarkers() {
    if (_currentPosition == null) return;
    _markers.add(
      Marker(
        markerId: const MarkerId("stationPosition"),
        position: widget.stationPosition,
        infoWindow: InfoWindow(title: widget.stationName),
        icon: _stationMarkerIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );
  }

  Future<void> _createPolylines() async {
    if (_currentPosition == null) return;

    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("Google API Key not found or is empty in .env file");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("API Key not configured. Cannot draw route.")),
        );
      }
      return;
    }

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: apiKey,
      request: PolylineRequest(
        origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: PointLatLng(widget.stationPosition.latitude, widget.stationPosition.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      Polyline polyline = Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.green,
        points: polylineCoordinates,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      if (mounted) {
        setState(() {
          _polylines.add(polyline);
        });
        _animateCameraToFitRoute();
      }
    } else {
      debugPrint("Could not get polyline points: ${result.errorMessage}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not draw route: ${result.errorMessage}")),
        );
      }
    }
  }

  Future<void> _animateCameraToFitRoute() async {
    if (_mapController == null || _currentPosition == null) return;

    await Future.delayed(const Duration(milliseconds: 250));

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        min(_currentPosition!.latitude, widget.stationPosition.latitude),
        min(_currentPosition!.longitude, widget.stationPosition.longitude),
      ),
      northeast: LatLng(
        max(_currentPosition!.latitude, widget.stationPosition.latitude),
        max(_currentPosition!.longitude, widget.stationPosition.longitude),
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 75.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _mapController != null
          ? FloatingActionButton(
              onPressed: _animateCameraToFitRoute,
              backgroundColor: Colors.white,
              child: const Icon(Icons.zoom_out_map, color: Colors.green),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentPosition == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                "Location Not Found",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "We couldn't get your current location. Please make sure location services are enabled and permissions are granted.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        if (_mapStyle != null) {
          _mapController!.setMapStyle(_mapStyle);
        }
        if (_polylines.isNotEmpty) {
          _animateCameraToFitRoute();
        }
      },
      initialCameraPosition: CameraPosition(
        target: _currentPosition!,
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
