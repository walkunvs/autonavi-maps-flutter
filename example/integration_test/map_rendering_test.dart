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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

import 'test_app/map_test_app.dart';

// How long to wait for the map tiles and SDK to fully render after pump.
const _mapSettleTimeout = Duration(seconds: 5);

// Pixel-difference threshold passed to the CI golden_diff.py script.
// Stored here as documentation; the CI script receives it as a CLI argument.
const _goldenThresholdPercent = 2.0; // 2 %

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // Basic map rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Map renders without overlays', (tester) async {
    await tester.pumpWidget(const MapTestApp());
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);

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
    await tester.pumpAndSettle(_mapSettleTimeout);
    await binding.takeScreenshot('marker_update_before');

    // Move the marker to position B to trigger markers#update channel call.
    markerState.value = {
      Marker(
        markerId: const MarkerId('dynamic'),
        position: const LatLng(31.2500, 121.4900),
      ),
    };
    await tester.pumpAndSettle(_mapSettleTimeout);
    await binding.takeScreenshot('marker_update_after');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Save screenshots for golden comparison
  //
  // After all tests, copy captured screenshots to the screenshots/ directory
  // so that the CI golden_diff.py script can compare them against golden/.
  // ─────────────────────────────────────────────────────────────────────────

  tearDownAll(() async {
    final screenshotsDir = Directory('integration_test/screenshots');
    if (!screenshotsDir.existsSync()) {
      screenshotsDir.createSync(recursive: true);
    }

    // IntegrationTestWidgetsFlutterBinding.takeScreenshot stores screenshots
    // in memory; write them out to disk here.
    for (final entry in binding.screenshotData.entries) {
      final file = File('${screenshotsDir.path}/${entry.key}.png');
      file.writeAsBytesSync(entry.value);
    }
  });
}
