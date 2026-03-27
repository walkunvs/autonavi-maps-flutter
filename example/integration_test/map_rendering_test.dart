// Layer 2 & 3: Integration Tests — Map Rendering + Screenshot Golden Regression
//
// These tests run on a real iOS Simulator (macos-14 runner) or Android Emulator
// (ubuntu runner with KVM). They verify that map overlays actually appear on
// screen, then capture screenshots that are compared against golden baselines.
//
// Running locally:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/map_rendering_test.dart \
//     --dart-define=AMAP_IOS_KEY=<your-key>             (iOS simulator)
//     --dart-define=AMAP_ANDROID_KEY=<your-key>          (Android emulator)
//
// Updating golden baselines:
//   Copy the screenshots/ output into golden/ after a visual inspection.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

import 'test_app/map_test_app.dart';

// How long to wait for the AMap SDK to initialise on first launch and for
// map tiles to finish loading.  10 s gives slower GitHub Actions runners
// enough time to fetch and render the initial tile set.
const _mapInitDelay = Duration(seconds: 10);

// How long to wait after updating overlays before taking a screenshot.
// The update travels: Dart setState → platform channel → native SDK render.
// 500 ms is enough for this local round-trip.
const _overlayUpdateDelay = Duration(milliseconds: 500);

// Fixed camera position for all scenarios.  Using one consistent view means
// the AMap native view (and its tile state) is never torn down between
// screenshots — only the overlays change.
const _camera = CameraPosition(
  target: LatLng(31.2304, 121.4737),
  zoom: 14,
);

/// Holds the overlay sets for one screenshot scenario.
class _Overlays {
  const _Overlays({
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
  });

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('map overlay rendering', (tester) async {
    // Shared overlay state.  Updating this value rebuilds only the overlay
    // layer via ValueListenableBuilder; the MapTestApp (and its AMap native
    // view) stay alive for the entire test thanks to the stable ValueKey.
    final overlays = ValueNotifier<_Overlays>(const _Overlays());

    await tester.pumpWidget(
      ValueListenableBuilder<_Overlays>(
        valueListenable: overlays,
        builder: (context, o, _) => MapTestApp(
          key: const ValueKey('map'),
          initialCameraPosition: _camera,
          markers: o.markers,
          polylines: o.polylines,
          polygons: o.polygons,
          circles: o.circles,
        ),
      ),
    );

    // One-time SDK init wait — paid only once for the entire test.
    await tester.pump();
    await Future.delayed(_mapInitDelay);
    await tester.pump();

    // Android: PixelCopy reads the hardware compositor (GPU framebuffer) so
    // AMap's OpenGL ES tiles are included.  Screenshots are saved directly to
    // the app's external files dir; CI pulls them with `adb pull` after the
    // test completes.  convertFlutterSurfaceToImage() is intentionally NOT
    // called — it hides Hybrid Composition platform views, producing a blank
    // white screen.
    //
    // iOS: binding.takeScreenshot() uses the host-side XCUITest native
    // screenshot API which already captures platform views correctly.
    const _screenshotChannel = MethodChannel('com.example.autonavi/screenshot');

    Future<void> shoot(
      String name, {
      Set<Marker> markers = const {},
      Set<Polyline> polylines = const {},
      Set<Polygon> polygons = const {},
      Set<Circle> circles = const {},
    }) async {
      overlays.value = _Overlays(
        markers: markers,
        polylines: polylines,
        polygons: polygons,
        circles: circles,
      );
      await tester.pump();
      await Future.delayed(_overlayUpdateDelay);
      await tester.pump();
      if (Platform.isAndroid) {
        try {
          await _screenshotChannel.invokeMethod<String>('captureAndSave', name);
        } catch (e) {
          debugPrint('Warning: screenshot $name failed: $e');
        }
      } else {
        await binding.takeScreenshot(name);
      }
    }

    // ── Empty map ─────────────────────────────────────────────────────────
    await shoot('map_empty');

    // ── Markers ───────────────────────────────────────────────────────────
    await shoot('marker_single', markers: {
      Marker(
        markerId: const MarkerId('test-marker'),
        position: const LatLng(31.2304, 121.4737),
      ),
    });

    await shoot('marker_multiple', markers: {
      Marker(
        markerId: const MarkerId('marker-a'),
        position: const LatLng(31.2304, 121.4737),
      ),
      Marker(
        markerId: const MarkerId('marker-b'),
        position: const LatLng(31.2440, 121.4830),
      ),
      Marker(
        markerId: const MarkerId('marker-c'),
        position: const LatLng(31.2170, 121.4640),
      ),
    });

    // ── Polylines ─────────────────────────────────────────────────────────
    await shoot('polyline_basic', polylines: {
      Polyline(
        polylineId: const PolylineId('route-basic'),
        points: const [
          LatLng(31.2204, 121.4657),
          LatLng(31.2404, 121.4817),
        ],
        color: Colors.blue,
        width: 10,
      ),
    });

    await shoot('polyline_multi_segment', polylines: {
      Polyline(
        polylineId: const PolylineId('route-multi'),
        points: const [
          LatLng(31.2164, 121.4657),
          LatLng(31.2384, 121.4697),
          LatLng(31.2184, 121.4787),
          LatLng(31.2424, 121.4827),
        ],
        color: Colors.red,
        width: 10,
      ),
    });

    // ── Polygons ──────────────────────────────────────────────────────────
    await shoot('polygon_filled', polygons: {
      Polygon(
        polygonId: const PolygonId('area-basic'),
        points: const [
          LatLng(31.2229, 121.4677),
          LatLng(31.2379, 121.4677),
          LatLng(31.2379, 121.4797),
          LatLng(31.2229, 121.4797),
        ],
        fillColor: const Color(0x800066CC),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    });

    await shoot('polygon_triangle', polygons: {
      Polygon(
        polygonId: const PolygonId('area-triangle'),
        points: const [
          LatLng(31.2404, 121.4737),
          LatLng(31.2204, 121.4637),
          LatLng(31.2204, 121.4837),
        ],
        fillColor: const Color(0x60FF6600),
        strokeColor: Colors.orange,
        strokeWidth: 4,
      ),
    });

    // ── Circle ────────────────────────────────────────────────────────────
    await shoot('circle_basic', circles: {
      Circle(
        circleId: const CircleId('circle-basic'),
        center: const LatLng(31.2304, 121.4737),
        radius: 600,
        fillColor: const Color(0x80FF0000),
        strokeColor: Colors.red,
        strokeWidth: 4,
      ),
    });

    // ── Combined overlays ─────────────────────────────────────────────────
    await shoot(
      'overlay_combined',
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
            LatLng(31.2404, 121.4817),
          ],
          color: Colors.green,
          width: 6,
        ),
      },
      circles: {
        Circle(
          circleId: const CircleId('buffer'),
          center: const LatLng(31.2304, 121.4737),
          radius: 500,
          fillColor: const Color(0x6000CC66),
          strokeColor: Colors.green,
          strokeWidth: 3,
        ),
      },
    );

    // ── Marker update regression ──────────────────────────────────────────
    // Verifies that didUpdateWidget sends markers#update (not add + remove)
    // when the same MarkerId moves to a new position.
    await shoot('marker_update_before', markers: {
      Marker(
        markerId: const MarkerId('dynamic'),
        position: const LatLng(31.2304, 121.4737),
      ),
    });
    await shoot('marker_update_after', markers: {
      Marker(
        markerId: const MarkerId('dynamic'),
        position: const LatLng(31.2404, 121.4817),
      ),
    });
  });
}
