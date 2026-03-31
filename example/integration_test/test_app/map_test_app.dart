// A minimal Flutter app used exclusively by integration tests.
//
// The AutoNavi API key is injected at compile time via:
//   flutter test --dart-define=AMAP_IOS_KEY=<key>     (iOS)
//   flutter test --dart-define=AMAP_ANDROID_KEY=<key>  (Android)
//
// The widget is kept as thin as possible so tests control every overlay
// declaratively through the constructor parameters.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

const _iosKey = String.fromEnvironment('AMAP_IOS_KEY', defaultValue: '');
const _androidKey =
    String.fromEnvironment('AMAP_ANDROID_KEY', defaultValue: '');

/// Returns the correct AutoNavi API key for the current platform.
String get amapApiKey => Platform.isIOS ? _iosKey : _androidKey;

/// A minimal map host used by integration tests.
///
/// Pass [markers], [polylines], [polygons], or [circles] to render specific
/// overlays. The map is centered on Shanghai by default.
class MapTestApp extends StatefulWidget {
  const MapTestApp({
    super.key,
    this.initialCameraPosition = const CameraPosition(
      target: LatLng(31.2304, 121.4737),
      zoom: 12,
    ),
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
    this.onMapCreated,
  });

  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;
  final MapCreatedCallback? onMapCreated;

  @override
  State<MapTestApp> createState() => _MapTestAppState();
}

class _MapTestAppState extends State<MapTestApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: AutonaviWidget(
          initialCameraPosition: widget.initialCameraPosition,
          markers: widget.markers,
          polylines: widget.polylines,
          polygons: widget.polygons,
          circles: widget.circles,
          onMapCreated: widget.onMapCreated,
        ),
      ),
    );
  }
}
