// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// // Main widget for displaying Google Map
// class GoogleMapFlutter extends StatefulWidget {
//   const GoogleMapFlutter({super.key});

//   @override
//   State<GoogleMapFlutter> createState() => _GoogleMapFlutterState();
// }

// class _GoogleMapFlutterState extends State<GoogleMapFlutter> {
//   // Initial location for the map's camera position (latitude and longitude)
//   LatLng myCurrentLocation = const LatLng(27.7172, 85.3240);
//   // LatLng myCurrentLocation = const LatLng(28.578382, 81.63359);

//   late GoogleMapController googleMapController;
//   Set<Marker> markers = {};

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: GoogleMap(
//         myLocationButtonEnabled: false,

//         markers: markers,
//         // Setting the controller when the map is created
//         onMapCreated: (GoogleMapController controller) {
//           googleMapController = controller;
//         },
//         // Initial camera position of the map
//         initialCameraPosition: CameraPosition(
//           target: myCurrentLocation,
//           zoom: 14,
//         ),
//       ),
//       // Floating action button to get user's current location
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.white,
//         child: const Icon(
//           Icons.my_location,
//           size: 30,
//         ),
//         onPressed: () async {
//           // Getting the current position of the user
//           Position position = await currentPosition();

//           // Animating the camera to the user's current position
//           googleMapController.animateCamera(
//             CameraUpdate.newCameraPosition(
//               CameraPosition(
//                 target: LatLng(position.latitude, position.longitude),
//                 zoom: 14,
//               ),
//             ),
//           );

//           // Clearing existing markers
//           markers.clear();
//           // Adding a new marker at the user's current position
//           markers.add(
//             Marker(
//               markerId: const MarkerId('currentLocation'),
//               position: LatLng(position.latitude, position.longitude),
//             ),
//           );

//           // Refreshing the state to update the UI with new markers
//           setState(() {});
//         },
//       ),
//     );
//   }

//   // Function to determine the user's current position
//   Future<Position> currentPosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Checking if location services are enabled
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled');
//     }

//     // Checking the location permission status
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       // Requesting permission if it is denied
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error("Location permission denied");
//       }
//     }

//     // Handling the case where permission is permanently denied
//     if (permission == LocationPermission.deniedForever) {
//       return Future.error('Location permissions are permanently denied');
//     }

//     // Getting the current position of the user
//     Position position = await Geolocator.getCurrentPosition();
//     return position;
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class OpenstreetmapScreen extends StatefulWidget {
  const OpenstreetmapScreen({super.key});

  @override
  _OpenstreetmapScreenState createState() => _OpenstreetmapScreenState();
}

class _OpenstreetmapScreenState extends State<OpenstreetmapScreen> {
  final Location _locationService = Location();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Initialize and fetch user location
  Future<void> _initializeLocation() async {
    if (!await _checkAndRequestPermissions()) return;
//missing part 1
    _locationService.onLocationChanged.listen(
      (LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          setState(() {
            _currentLocation =
                LatLng(locationData.latitude!, locationData.longitude!);
            _isLoading = false;
          });
        }
      },
    );
  }

  /// Check and request permissions
  Future<bool> _checkAndRequestPermissions() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted == await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  ///Fetch coordinates for the entered location using Nomination API
  Future<void> _fetchCoordinates(String location) async {
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

        //Fetch route from current location to destination
        await _fetchRoute();
      } else {
        _showError('Location not found. Please try another search.');
      }
    } else {
      _showError('Failed to fetch location. Try again later.');
    }
  }

  /// Fetch shortest route using OSRM API
  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry'];
      final routePolyline = _decodePolyline(geometry);
      setState(() {
        _route =
            routePolyline.map((point) => LatLng(point[0], point[1])).toList();
      });
    } else {
      _showError('Failed to fetch route.Try again later.');
    }
  }

  /// Decode polyline from OSRM response
  List<List<double>> _decodePolyline(String polyline) {
    const factor = 1e5;
    List<List<double>> points = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lon = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;
      shift = 0;
      result = 0;

      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lon += dlng;
      points.add(
        [lat / factor, lon / factor],
      );
    }
    return points;
  }

  /// Show error message
  void _showError(String message) {
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
        title: const Text(
          "Map with Directions",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a location',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final location = _locationController.text.trim();
                    if (location.isNotEmpty) {
                      _fetchCoordinates(location);
                    }
                  },
                  icon: const Icon(Icons.search),
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : FlutterMap(
                    options: MapOptions(
                        initialCenter: _currentLocation ?? const LatLng(0, 0),
                        initialZoom: 1,
                        minZoom: 0,
                        maxZoom: 100),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      ),
                      // User's current location marker
                      CurrentLocationLayer(
                        alignPositionOnUpdate: AlignOnUpdate.always,
                        alignDirectionOnUpdate: AlignOnUpdate.never,
                        style: const LocationMarkerStyle(
                          marker: DefaultLocationMarker(
                            child: Icon(
                              Icons.navigation,
                              color: Colors.white,
                            ),
                          ),
                          markerSize: Size(40, 40),
                          markerDirection: MarkerDirection.heading,
                        ),
                      ),
                      // Destination marker
                      if (_destination != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                                point: _destination!,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ))
                          ],
                        ),
                      //Route polyline (red color)
                      if (_currentLocation != null &&
                          _destination != null &&
                          _route.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _route,
                              strokeWidth: 4.0,
                              color: Colors.red,
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}