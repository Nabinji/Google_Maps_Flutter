import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class OpenstreetmapScreen extends StatefulWidget {
  const OpenstreetmapScreen({super.key});

  @override
  State<OpenstreetmapScreen> createState() => _OpenstreetmapScreenState();
}

class _OpenstreetmapScreenState extends State<OpenstreetmapScreen> {
  final Location _locationService = Location();
  final TextEditingController _locationController = TextEditingController();
  final MapController _mapController = MapController();
  bool isLoading = true;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!await _checkRequestPermissions()) return;
    // listen for location updates and upadet he current location

    _locationService.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
          isLoading = false; // stop loadin once the cocation is obtained.
        });
      }
    });
  }

  Future<bool> _checkRequestPermissions() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  // Method to center the map on the current location.
  Future<void> userCurrentLocation() async {
    if (_currentLocation != null) {
      // Move the map to the current location with a zoom level of 15.
      _mapController.move(_currentLocation!, 14);
    } else {
      // Show a message if the current location is not available.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Current location not available."),
        ),
      );
    }
  }

  // Method to fetch coordinates for a given location using the OpenStreetMap Nominatim API.
  Future<void> _fetchCoordinatesPoints(String location) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        setState(() {
          _destination = LatLng(lat, lon);
        });
        await fetchRoute();
      } else {
        errorMessage('Location not found. Please try another search.');
      }
    } else {
      errorMessage('Failed to fetch location. Try again later.');
    }
  }

  // Method to fetch the route between the current location and the destination using the OSRM API.
  Future<void> fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry'];
      _decodePolyline(
          geometry); // Decode the polyline into a list of coordinates.
    } else {
      errorMessage('Failed to fetch route. Try again later.');
    }
  }

  // Method to decode a polyline string into a list of geographic coordinates.
  void _decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPoints =
        polylinePoints.decodePolyline(encodedPolyline);

    setState(() {
      _route = decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    });
  }

  // method to display an error message using a anackBar.
  void errorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("OpenStreetMap"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Show a loading indicator if the app is waiting for location data.
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(0, 0),
                    initialZoom: 2,
                    minZoom: 0,
                    maxZoom: 100,
                  ),
                  children: [
                    // TileLayer to display the OpenStreetMap tiles.
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    // CurrentLocationLayer to display the user's current location on the map.
                    CurrentLocationLayer(
                      style: const LocationMarkerStyle(
                        marker: DefaultLocationMarker(
                          child: Icon(Icons.location_pin, color: Colors.white),
                        ),
                        markerSize: Size(40, 40),
                        markerDirection: MarkerDirection.heading,
                      ),
                    ),
                    // MarkerLayer to display the destination marker on the map.
                    if (_destination != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _destination!,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    // PolylineLayer to display the route between the current location and the destination.
                    if (_currentLocation != null &&
                        _destination != null &&
                        _route.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                              points: _route,
                              strokeWidth: 4.0,
                              color: Colors.red),
                        ],
                      ),
                  ],
                ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Expanded widget to make the text field take up available space.
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter your location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  // IconButton to trigger the search for the entered location.
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {
                      final location = _locationController.text.trim();
                      if (location.isNotEmpty) {
                        _fetchCoordinatesPoints(
                            location); // Fetch coordinates for the entered location.
                      }
                    },
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: userCurrentLocation,
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.my_location,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}
