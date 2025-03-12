import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomInfoWindows extends StatefulWidget {
  const CustomInfoWindows({super.key});

  @override
  State<CustomInfoWindows> createState() => _CustomInfoWindowsState();
}

class _CustomInfoWindowsState extends State<CustomInfoWindows> {
  // Controller to manage the custom info window's behavior
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  // Set of markers to be displayed on the map
  Set<Marker> markers = {};

  // List of coordinates (LatLng) where markers will be placed
  final List<LatLng> latlongPoint = [
    const LatLng(28.5175, 81.7787), // Surkhet
    const LatLng(27.7293, 85.3343), // Kathmandu
    const LatLng(28.2096, 83.9856), // Pokhara
  ];

  // Corresponding names for the locations
  final List<String> locationNames = [
    "  Surkhet",
    "  Kathmandu",
    "  Pokhara",
  ];

  // Corresponding image URLs for the locations
  final List<String> locationImages = [
    "https://upload.wikimedia.org/wikipedia/en/0/0d/Surkhet_Airport_-_Aerial_View.jpg",
    "https://cdn.britannica.com/68/178668-050-DA998E6C/Durbar-Square-heart-district-Kathmandu-earthquake-Nepal-April-25-2015.jpg",
    "https://www.acethehimalaya.com/wp-content/uploads/2024/02/things-to-do-in-pokhara.jpg.webp",
  ];

  @override
  void initState() {
    super.initState();
    // Initialize and display the markers with custom info windows
    displayInfo();
  }

  // Function to add markers and custom info windows on the map
  displayInfo() {
    for (int i = 0; i < latlongPoint.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId(i.toString()), // Unique identifier for each marker
          icon: BitmapDescriptor.defaultMarker, // Default marker icon
          position: latlongPoint[i], // Position of the marker
          onTap: () {
            // When marker is tapped, show the custom info window
            _customInfoWindowController.addInfoWindow!(
              Container(
                color: Colors.white, // Background color of the info window
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display the corresponding image for the location
                    Image.network(
                      locationImages[i],
                      height: 125,
                      width: 250,
                      fit: BoxFit.cover,
                    ),
                    // const SizedBox(height: 4), // Spacer between image and text
                    // Display the corresponding name for the location

                    Text(
                      locationNames[i],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const   Row(
                   children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        Text("(5)")
                      ],
                    )
                  ],
                ),
              ),
              latlongPoint[
                  i], // Position where the info window should be displayed
            );
          },
        ),
      );
      setState(() {}); // Update the UI to reflect the added markers
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // GoogleMap widget to display the map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                  28.2096, 83.9856), // Initial position of the camera (Pokhara)
              zoom: 7, // Initial zoom level
            ),
            markers: markers, // Set of markers to be displayed on the map
            onTap: (argument) {
              // Hide the custom info window when the map is tapped
              _customInfoWindowController.hideInfoWindow!();
            },
            onCameraMove: (position) {
              // Update the position of the custom info window when the camera moves
              _customInfoWindowController.onCameraMove!();
            },
            onMapCreated: (GoogleMapController controller) {
              // Assign the map controller to the custom info window controller
              _customInfoWindowController.googleMapController = controller;
            },
          ),
          // Widget that manages the custom info windows
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 171, // Height of the custom info window
            width: 250, // Width of the custom info window
            offset: 35, // Offset to position the info window above the marker
          ),
        ],
      ),
    );
  }
}
