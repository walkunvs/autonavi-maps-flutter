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

// How long to wait for AMap tiles to load from the network.
// AMap tiles are fetched asynchronously from a CDN and are NOT captured by
// pumpAndSettle (which only drains Flutter's frame scheduler).
// 15 s covers cold-start latency on GitHub Actions macOS/ubuntu runners.
const _tilePaintDelay = Duration(seconds: 15);

/// Waits for AMap tiles, then converts the Flutter surface to a raster image.
///
/// Call order matters:
///   1. pump() — kick off the initial render so the native map view exists.
///   2. Future.delayed — let the CDN tiles finish loading (outside Flutter's
///      frame scheduler, so pumpAndSettle cannot observe this).
///   3. pump() — sync Flutter with whatever the native layer has painted.
///   4. convertFlutterSurfaceToImage() — switch to image-capture mode AFTER
///      tiles are already on screen; calling it earlier can interfere with the
///      platform-view rendering path on iOS Simulator.
///   5. pump() — one final frame so the image surface reflects the tiles.
///
/// Must be called **exactly once** per test (the framework asserts
/// !_isSurfaceRendered on every call).
Future<void> _prepareForScreenshots(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  await tester.pump();
  await Future.delayed(_tilePaintDelay);
  await tester.pump();
  await binding.convertFlutterSurfaceToImage();
  await tester.pump();
}

/// Takes a screenshot.  [_prepareForScreenshots] must have been called first.
/// For tests that take more than one screenshot, call this helper for each
/// screenshot WITHOUT calling [_prepareForScreenshots] again.
Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // Basic map rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Map renders without overlays', (tester) async {
    await tester.pumpWidget(const MapTestApp());
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'map_empty');
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
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'marker_single');
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
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'marker_multiple');
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
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'polyline_basic');
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
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'polyline_multi_segment');
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
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'polygon_filled');
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Circle rendering
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Circle renders at center with correct radius', (tester) async {
    await tester.pumpWidget(
      MapTestApp(
        // Zoom in so a 1 km circle is large enough to see clearly.
        initialCameraPosition: const CameraPosition(
          target: LatLng(31.2304, 121.4737),
          zoom: 15,
        ),
        circles: {
          Circle(
            circleId: const CircleId('circle-basic'),
            center: const LatLng(31.2304, 121.4737),
            radius: 1000, // 1 km radius
            fillColor: const Color(0x80FF0000), // opaque enough to be visible
            strokeColor: Colors.red,
            strokeWidth: 4,
          ),
        },
      ),
    );
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'circle_basic');
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
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'overlay_combined');
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
    // convertFlutterSurfaceToImage is called exactly once for this test.
    await _prepareForScreenshots(binding, tester);
    await _screenshot(binding, 'marker_update_before');

    // Move the marker to position B to trigger markers#update channel call.
    markerState.value = {
      Marker(
        markerId: const MarkerId('dynamic'),
        position: const LatLng(31.2500, 121.4900),
      ),
    };
    // Do NOT call _prepareForScreenshots again — surface is already converted.
    await tester.pump();
    await Future.delayed(_tilePaintDelay);
    await tester.pump();
    await _screenshot(binding, 'marker_update_after');
  });

}
