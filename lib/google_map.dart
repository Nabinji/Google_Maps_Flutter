import 'package:flutter/material.dart';
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

  // Variable to store the custom marker icon
  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    customMarker(); // Call to function that sets the custom marker
    super.initState();
  }

  // Function to set a custom marker icon
  void customMarker() {
    // Load the custom marker image from the assets and set it as the marker icon
    BitmapDescriptor.asset(
      const ImageConfiguration(),
      "assets/images/buspark1.png",
    ).then((icon) {
      setState(() {
        customIcon = icon; // Update the state with the custom icon
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: myCurrentLocation, zoom: 14),
        markers: {
          Marker(
            markerId: const MarkerId("Marker Id"),
            position: myCurrentLocation,
            draggable: true, // Allow the marker to be draggable
            infoWindow: const InfoWindow(
                title: "Bus Park",
                snippet: "Local bus park area of kathmandu district Nepal."),
            onDragEnd: (value) {},
            icon: customIcon, // Icon for the marker (custom icon in this case)
          ),
        },
      ),
    );
  }
}
