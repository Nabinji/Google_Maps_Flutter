import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPolygon extends StatefulWidget {
  const GoogleMapPolygon({super.key});

  @override
  State<GoogleMapPolygon> createState() => _GoogleMapPolygonState();
}

class _GoogleMapPolygonState extends State<GoogleMapPolygon> {
  LatLng myCurrentLocation = const LatLng(28.578382, 81.63359);
  final Completer<GoogleMapController> _completer = Completer();

  Set<Marker> markers = {};

  Set<Polygon> polygone = HashSet<Polygon>();
  List<LatLng> points = [
    const LatLng(28.590588580409996, 81.62249412839972),
    const LatLng(28.591741874823285, 81.62017942031399),
    const LatLng(28.592176720251853, 81.61910281190202),
    const LatLng(28.595097700526917, 81.61798313915357),
    const LatLng(28.597130049917997, 81.6190920458179),
    const LatLng(28.594067331637813, 81.6248411347378),
    const LatLng(28.590588580409996, 81.62249412839972),
  ];
  void addPolygon() {
    polygone.add(
      Polygon(
        polygonId: const PolygonId("Id"),
        points: points,
        strokeColor: Colors.blueAccent,
        strokeWidth: 5,
        fillColor: Colors.green.withOpacity(0.1),
        geodesic: true,
      ),
    );
  }

  @override
  void initState() {
    addPolygon();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      polygons: polygone,
      myLocationButtonEnabled: false,
      markers: markers,
      initialCameraPosition: CameraPosition(
        target: myCurrentLocation,
        zoom: 14,
      ),
      onMapCreated: (GoogleMapController controller) {
        _completer.complete(controller);
      },
    );
  }
}
