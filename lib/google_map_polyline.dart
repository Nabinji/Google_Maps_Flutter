import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Stateful widget to display Google Map with polyline
class GoogleMapPolyline extends StatefulWidget {
  const GoogleMapPolyline({super.key});

  @override
  State<GoogleMapPolyline> createState() => _GoogleMapPolylineState();
}

class _GoogleMapPolylineState extends State<GoogleMapPolyline> {
  // Define the initial location
  LatLng myCurrentLocation = const LatLng(28.578382, 81.63359);

  // Set of markers to place on the map
  Set<Marker> markers = {};

  // Set of polylines to draw on the map
  final Set<Polyline> _polyline = {};

  // List of points that define the polyline
  List<LatLng> pointOnMap = [
    const LatLng(28.568787, 81.629243),
    const LatLng(28.579754, 81.633865),
    const LatLng(28.591831, 81.616543),
    const LatLng(28.600745, 81.613678),
    const LatLng(28.591831, 81.616543),
    const LatLng(28.600792, 81.596041)
  ];

  @override
  void initState() {
    super.initState();

    // Add markers and polyline points
    for (int i = 0; i < pointOnMap.length; i++) {
      // Add a marker at each point
      markers.add(
        Marker(
          markerId: MarkerId(i.toString()), // Unique ID for each marker
          position: pointOnMap[i], // Position of the marker
          infoWindow: const InfoWindow(
            title: "Placed around Surkhet", // Title of the info window
            snippet: "So Beautiful", // Snippet text of the info window
          ),
          icon: BitmapDescriptor.defaultMarker, // Default marker icon
        ),
      );

      // Add polyline connecting all points
      setState(() {
        _polyline.add(
          Polyline(
            polylineId: const PolylineId("ID"), // Unique ID for the polyline
            points: pointOnMap, // Points that make up the polyline
            color: Colors.blue, // Color of the polyline
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        polylines: _polyline, // Set of polylines to display
        myLocationButtonEnabled: false, // Disable the my location button
        markers: markers, // Set of markers to display
        initialCameraPosition: CameraPosition(
          target: myCurrentLocation, // Initial position of the camera
          zoom: 13.8, // Initial zoom level of the camera
        ),
      ),
    );
  }
}
