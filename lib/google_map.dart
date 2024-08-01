import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const LatLng myCurrentLocation = LatLng(28.5175, 81.7787);

class GoogleMapHomePage extends StatefulWidget {
  const GoogleMapHomePage({super.key});

  @override
  State<GoogleMapHomePage> createState() => _GoogleMapHomePageState();
}

class _GoogleMapHomePageState extends State<GoogleMapHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: myCurrentLocation,
          zoom: 15
        ),
      ),
    );
  }
}
