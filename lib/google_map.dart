import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Main widget for displaying Google Map
class GoogleMapFlutter extends StatefulWidget {
  const GoogleMapFlutter({super.key});

  @override
  State<GoogleMapFlutter> createState() => _GoogleMapFlutterState();
}

class _GoogleMapFlutterState extends State<GoogleMapFlutter> {
  // Initial location for the map's camera position (latitude and longitude)
  LatLng myCurrentLocation = const LatLng(27.7172, 85.3240);
  // LatLng myCurrentLocation = const LatLng(28.578382, 81.63359);

  late GoogleMapController googleMapController;
  Set<Marker> markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationButtonEnabled: false,

        markers: markers,
        // Setting the controller when the map is created
        onMapCreated: (GoogleMapController controller) {
          googleMapController = controller;
        },
        // Initial camera position of the map
        initialCameraPosition: CameraPosition(
          target: myCurrentLocation,
          zoom: 14,
        ),
      ),
      // Floating action button to get user's current location
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          size: 30,
        ),
        onPressed: () async {
          // Getting the current position of the user
          Position position = await currentPosition();

          // Animating the camera to the user's current position
          googleMapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 14,
              ),
            ),
          );

          // Clearing existing markers
          markers.clear();
          // Adding a new marker at the user's current position
          markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
            ),
          );

          // Refreshing the state to update the UI with new markers
          setState(() {});
        },
      ),
    );
  }

  // Function to determine the user's current position
  Future<Position> currentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Checking if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    // Checking the location permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Requesting permission if it is denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }

    // Handling the case where permission is permanently denied
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // Getting the current position of the user
    Position position = await Geolocator.getCurrentPosition();
    return position;
  }
}
