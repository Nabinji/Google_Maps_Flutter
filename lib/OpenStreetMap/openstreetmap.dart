import 'dart:convert'; // For decoding JSON responses from APIs.
import 'package:flutter/material.dart'; // Flutter's UI framework for building the app interface.
import 'package:flutter_map/flutter_map.dart'; // For integrating OpenStreetMap in Flutter.
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart'; // For displaying the user's current location on the map.
import 'package:latlong2/latlong.dart'; // For handling geographic coordinates (latitude and longitude).
import 'package:location/location.dart'; // For accessing the device's location services.
import 'package:http/http.dart' as http; // For making HTTP requests to APIs.
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // For decoding polylines into geographic coordinates.

// The main screen widget that displays the OpenStreetMap and handles location-based features.
class OpenstreetmapScreen extends StatefulWidget {
  const OpenstreetmapScreen({super.key});

  @override
  _OpenstreetmapScreenState createState() => _OpenstreetmapScreenState();
}

// The state class for the OpenstreetmapScreen widget.
class _OpenstreetmapScreenState extends State<OpenstreetmapScreen> {
  // Location service to access the device's location.
  final Location _locationService = Location();
  // Controller for the text field where users input their destination.
  final TextEditingController _locationController = TextEditingController();
  // Controller for managing map operations like moving and zooming.
  final MapController _mapController = MapController();
  // Boolean to indicate if the app is waiting for location data.
  bool _isLoading = true;
  // Stores the current location coordinates (latitude and longitude).
  LatLng? _currentLocation;
  // Stores the destination coordinates (latitude and longitude).
  LatLng? _destination;
  // Stores the route points between the current location and the destination.
  List<LatLng> _route = [];

  // Initialize the current location when the screen loads.
  @override
  void initState() {
    super.initState();
    _initializeLocation(); // Call the method to initialize location services.
  }

  // Method to initialize location services and listen for location updates.
  Future<void> _initializeLocation() async {
    // Check and request location permissions before proceeding.
    if (!await _checkAndRequestPermissions()) return;

    // Listen for location updates and update the current location.
    _locationService.onLocationChanged.listen(
      (LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          setState(() {
            _currentLocation =
                LatLng(locationData.latitude!, locationData.longitude!);
            _isLoading = false; // Stop loading once the location is obtained.
          });
        }
      },
    );
  }

  // Method to check if location services are enabled and request permissions if necessary.
  Future<bool> _checkAndRequestPermissions() async {
    // Check if location services are enabled.
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      // Request to enable location services if they are not enabled.
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled)
        return false; // Return false if services are not enabled.
    }
    // Check if location permissions are granted.
    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      // Request location permissions if they are not granted.
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted)
        return false; // Return false if permissions are not granted.
    }
    return true; // Return true if permissions are granted.
  }

  // Method to center the map on the current location.
  Future<void> _centerToCurrentLocation() async {
    if (_currentLocation != null) {
      // Move the map to the current location with a zoom level of 15.
      _mapController.move(_currentLocation!, 15);
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
  Future<void> _fetchCoordinates(String location) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        // Extract latitude and longitude from the API response.
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        setState(() {
          _destination = LatLng(lat, lon); // Set the destination coordinates.
        });
        await _fetchRoute(); // Fetch the route to the destination.
      } else {
        errorMessage('Location not found. Please try another search.');
      }
    } else {
      errorMessage('Failed to fetch location. Try again later.');
    }
  }

  // Method to fetch the route between the current location and the destination using the OSRM API.
  Future<void> _fetchRoute() async {
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
          .toList(); // Convert the decoded points into LatLng objects.
    });
  }

  // Method to display an error message using a SnackBar.
  void errorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // Build method to create the UI of the screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("OpenStreetMap"),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Show a loading indicator if the app is waiting for location data.
          _isLoading
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
          // Positioned widget to place the search bar at the top of the screen.
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
                        hintText: 'Enter a location',
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
                    onPressed: () {
                      final location = _locationController.text.trim();
                      if (location.isNotEmpty) {
                        _fetchCoordinates(
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
      // FloatingActionButton to center the map on the current location.
      floatingActionButton: FloatingActionButton(
        onPressed: _centerToCurrentLocation,
        backgroundColor: Colors.green,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
