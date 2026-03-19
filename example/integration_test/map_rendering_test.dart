// Layer 2 & 3: Integration Tests — Map Rendering + Screenshot Golden Regression
//
// These tests run on a real iOS Simulator (macos-14 runner) or Android Emulator
// (ubuntu runner with KVM). They verify that map overlays actually appear on
// screen, then capture screenshots that are compared against golden baselines.
//
// Running locally:
//   flutter test integration_test/map_rendering_test.dart \
//     --dart-define=AMAP_IOS_KEY=<your-key>             (iOS simulator)
//     --dart-define=AMAP_ANDROID_KEY=<your-key>          (Android emulator)
//
// Updating golden baselines:
//   Copy the screenshots/ output into golden/ after a visual inspection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

import 'test_app/map_test_app.dart';

// How long to wait for AMap tiles to load from the network after Flutter
// settles. AMap tiles are fetched asynchronously from a CDN and are NOT
// captured by pumpAndSettle (which only drains Flutter's frame scheduler).
// The first test on a cold runner may need 8–10 s; subsequent tests are
// faster because tiles are cached by the OS.
const _tilePaintDelay = Duration(seconds: 8);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // Basic map rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Map renders without overlays', (tester) async {
    await tester.pumpWidget(const MapTestApp());
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('map_empty');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Marker rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Single marker renders at correct position', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        markers: {
          Marker(
            markerId: const MarkerId('test-marker'),
            position: const LatLng(31.2304, 121.4737),
          ),
        },
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('marker_single');
  });

  testWidgets('Multiple markers render at distinct positions', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        markers: {
          Marker(
            markerId: const MarkerId('marker-a'),
            position: const LatLng(31.2304, 121.4737),
          ),
          Marker(
            markerId: const MarkerId('marker-b'),
            position: const LatLng(31.2500, 121.4900),
          ),
          Marker(
            markerId: const MarkerId('marker-c'),
            position: const LatLng(31.2100, 121.4500),
          ),
        },
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('marker_multiple');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Polyline rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Polyline renders between two points', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        polylines: {
          Polyline(
            polylineId: const PolylineId('route-basic'),
            points: const [
              LatLng(31.2304, 121.4737),
              LatLng(31.2500, 121.4900),
            ],
            color: Colors.blue,
            width: 5,
          ),
        },
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('polyline_basic');
  });

  testWidgets('Multi-segment polyline renders correctly', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        polylines: {
          Polyline(
            polylineId: const PolylineId('route-multi'),
            points: const [
              LatLng(31.2100, 121.4400),
              LatLng(31.2304, 121.4737),
              LatLng(31.2500, 121.4900),
              LatLng(31.2700, 121.5100),
            ],
            color: Colors.red,
            width: 8,
          ),
        },
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('polyline_multi_segment');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Polygon rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Filled polygon renders with correct color', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        polygons: {
          Polygon(
            polygonId: const PolygonId('area-basic'),
            points: const [
              LatLng(31.2200, 121.4500),
              LatLng(31.2400, 121.4500),
              LatLng(31.2400, 121.4900),
              LatLng(31.2200, 121.4900),
            ],
            fillColor: const Color(0x800066CC),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        },
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('polygon_filled');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Circle rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Circle renders at center with correct radius', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        circles: {
          Circle(
            circleId: const CircleId('circle-basic'),
            center: const LatLng(31.2304, 121.4737),
            radius: 1000, // 1 km radius
            fillColor: const Color(0x40FF0000),
            strokeColor: Colors.red,
            strokeWidth: 2,
          ),
        },
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('circle_basic');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Combined overlays
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Multiple overlay types render together', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        markers: {
          Marker(
            markerId: const MarkerId('origin'),
            position: const LatLng(31.2304, 121.4737),
          ),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: const [
              LatLng(31.2304, 121.4737),
              LatLng(31.2500, 121.4900),
            ],
            color: Colors.green,
            width: 4,
          ),
        },
        circles: {
          Circle(
            circleId: const CircleId('buffer'),
            center: const LatLng(31.2304, 121.4737),
            radius: 500,
            fillColor: const Color(0x2000CC66),
            strokeColor: Colors.green,
            strokeWidth: 1,
          ),
        },
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();

    await binding.takeScreenshot('overlay_combined');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Overlay update regression
  //
  // This test verifies that didUpdateWidget correctly sends markers#update
  // over the Platform Channel and that the map reflects the change.
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Marker updates are reflected after widget rebuild',
      (tester) async {
    // Initial state: one marker at position A.
    final markerState = ValueNotifier<Set<Marker>>(
      {
        Marker(
          markerId: const MarkerId('dynamic'),
          position: const LatLng(31.2304, 121.4737),
        ),
      },
    );

    await tester.pumpWidget(
      ValueListenableBuilder<Set<Marker>>(
        valueListenable: markerState,
        builder: (context, markers, _) => MapTestApp(markers: markers),
      ),
    );
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();
    await binding.takeScreenshot('marker_update_before');

    // Move the marker to position B to trigger markers#update channel call.
    markerState.value = {
      Marker(
        markerId: const MarkerId('dynamic'),
        position: const LatLng(31.2500, 121.4900),
      ),
    };
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();
    await binding.takeScreenshot('marker_update_after');
  });

}
