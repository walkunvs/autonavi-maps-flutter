// Layer 1: Platform Channel Contract Tests
//
// These tests verify the data contract between Flutter and the native AutoNavi
// SDK across the Platform Channel. They ensure serialization format, parameter
// naming, and data structures are correct without requiring a real device.
//
// The contract covers three levels:
//  1. Type serialization — what individual objects look like when encoded
//  2. Update payloads  — what the markers#update / polylines#update calls carry
//  3. Controller RPC   — that AutonaviController sends the right method names
//
// Full round-trip (markers#update triggered by didUpdateWidget) is covered by
// the integration tests in example/integration_test/.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';
import 'package:autonavi_maps_flutter/src/utils/marker_updates.dart';
import 'package:autonavi_maps_flutter/src/utils/polyline_updates.dart';
import 'package:autonavi_maps_flutter/src/utils/polygon_updates.dart';
import 'package:autonavi_maps_flutter/src/utils/circle_updates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // LatLng serialization
  // ─────────────────────────────────────────────────────────────────────────

  group('LatLng channel contract', () {
    test('toJson encodes as {latitude, longitude} map (not a list)', () {
      const latLng = LatLng(31.23, 121.47);
      final json = latLng.toJson();

      // Native side reads 'latitude' and 'longitude' keys — must NOT be a list.
      expect(json, equals({'latitude': 31.23, 'longitude': 121.47}));
    });

    test('fromJson round-trips correctly', () {
      const original = LatLng(39.909187, 116.397451);
      final decoded = LatLng.fromJson(original.toJson());

      expect(decoded, equals(original));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CameraPosition serialization
  // ─────────────────────────────────────────────────────────────────────────

  group('CameraPosition channel contract', () {
    test('toJson contains target, zoom, bearing, tilt', () {
      const pos = CameraPosition(
        target: LatLng(31.23, 121.47),
        zoom: 14.0,
        bearing: 90.0,
        tilt: 45.0,
      );
      final json = pos.toJson();

      expect(json['target'], equals({'latitude': 31.23, 'longitude': 121.47}));
      expect(json['zoom'], 14.0);
      expect(json['bearing'], 90.0);
      expect(json['tilt'], 45.0);
    });

    test('fromJson round-trips correctly', () {
      const original = CameraPosition(
        target: LatLng(22.5431, 114.0579),
        zoom: 10.5,
      );
      final decoded = CameraPosition.fromJson(original.toJson());

      expect(decoded.target, equals(original.target));
      expect(decoded.zoom, original.zoom);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Marker serialization
  // ─────────────────────────────────────────────────────────────────────────

  group('Marker channel contract', () {
    test('toJson contains markerId string value', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(31.23, 121.47),
      );
      final json = marker.toJson();

      expect(json['markerId'], equals('m1'));
    });

    test('position is encoded as {latitude, longitude} map', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(31.23, 121.47),
      );
      final json = marker.toJson();

      expect(
        json['position'],
        equals({'latitude': 31.23, 'longitude': 121.47}),
      );
    });

    test('anchor is encoded as {dx, dy} map', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(0, 0),
        anchor: const Offset(0.5, 1.0),
      );
      final json = marker.toJson();

      expect(json['anchor'], equals({'dx': 0.5, 'dy': 1.0}));
    });

    test('toJson contains all required native-readable keys', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(31.23, 121.47),
      );
      final json = marker.toJson();

      for (final key in [
        'markerId',
        'position',
        'alpha',
        'anchor',
        'consumeTapEvents',
        'draggable',
        'flat',
        'icon',
        'infoWindow',
        'rotation',
        'visible',
        'zIndex',
      ]) {
        expect(json.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('default values are serialized correctly', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(0, 0),
      );
      final json = marker.toJson();

      expect(json['alpha'], 1.0);
      expect(json['rotation'], 0.0);
      expect(json['visible'], isTrue);
      expect(json['draggable'], isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Polyline serialization
  // ─────────────────────────────────────────────────────────────────────────

  group('Polyline channel contract', () {
    test('toJson encodes points as list of {latitude, longitude} maps', () {
      final polyline = Polyline(
        polylineId: const PolylineId('route1'),
        points: const [LatLng(31.23, 121.47), LatLng(31.25, 121.49)],
        color: const Color(0xFF0000FF),
        width: 5,
      );
      final json = polyline.toJson();

      final points = json['points'] as List;
      expect(points, hasLength(2));
      expect(points[0], equals({'latitude': 31.23, 'longitude': 121.47}));
      expect(points[1], equals({'latitude': 31.25, 'longitude': 121.49}));
    });

    test('color is encoded as integer ARGB value', () {
      final polyline = Polyline(
        polylineId: const PolylineId('p1'),
        color: const Color(0xFF0066CC),
      );
      final json = polyline.toJson();

      expect(json['color'], equals(const Color(0xFF0066CC).value));
    });

    test('polylineId is encoded as string', () {
      final polyline = Polyline(polylineId: const PolylineId('route-abc'));
      final json = polyline.toJson();

      expect(json['polylineId'], equals('route-abc'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Polygon serialization
  // ─────────────────────────────────────────────────────────────────────────

  group('Polygon channel contract', () {
    test('toJson encodes points as list of {latitude, longitude} maps', () {
      final polygon = Polygon(
        polygonId: const PolygonId('area1'),
        points: const [
          LatLng(31.20, 121.40),
          LatLng(31.25, 121.40),
          LatLng(31.25, 121.50),
          LatLng(31.20, 121.50),
        ],
        fillColor: const Color(0x800066CC),
        strokeColor: const Color(0xFF0066CC),
        strokeWidth: 3,
      );
      final json = polygon.toJson();

      final points = json['points'] as List;
      expect(points, hasLength(4));
      expect(points[0], equals({'latitude': 31.20, 'longitude': 121.40}));
    });

    test('fill and stroke colors are encoded as integer ARGB values', () {
      final polygon = Polygon(
        polygonId: const PolygonId('p1'),
        fillColor: const Color(0x800066CC),
        strokeColor: const Color(0xFF0066CC),
      );
      final json = polygon.toJson();

      expect(json['fillColor'], equals(const Color(0x800066CC).value));
      expect(json['strokeColor'], equals(const Color(0xFF0066CC).value));
    });

    test('holes are encoded as list of lists of {latitude, longitude} maps',
        () {
      final polygon = Polygon(
        polygonId: const PolygonId('donut'),
        points: const [
          LatLng(31.20, 121.40),
          LatLng(31.30, 121.40),
          LatLng(31.30, 121.50),
          LatLng(31.20, 121.50),
        ],
        holes: const [
          [
            LatLng(31.22, 121.42),
            LatLng(31.28, 121.42),
            LatLng(31.28, 121.48),
            LatLng(31.22, 121.48),
          ],
        ],
      );
      final json = polygon.toJson();

      final holes = json['holes'] as List;
      expect(holes, hasLength(1));
      final hole = holes[0] as List;
      expect(hole, hasLength(4));
      expect(hole[0], equals({'latitude': 31.22, 'longitude': 121.42}));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MarkerUpdates — payload for markers#update channel call
  // ─────────────────────────────────────────────────────────────────────────

  group('MarkerUpdates channel contract (markers#update payload)', () {
    test('new marker goes into markersToAdd', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(31.23, 121.47),
      );
      final updates = MarkerUpdates.from({}, {marker});
      final json = updates.toJson();

      final toAdd = json['markersToAdd'] as List;
      expect(toAdd, hasLength(1));
      expect((toAdd[0] as Map)['markerId'], equals('m1'));
    });

    test('removed marker id goes into markerIdsToRemove', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(31.23, 121.47),
      );
      final updates = MarkerUpdates.from({marker}, {});
      final json = updates.toJson();

      final toRemove = json['markerIdsToRemove'] as List;
      expect(toRemove, contains('m1'));
      expect((json['markersToAdd'] as List), isEmpty);
    });

    test('changed marker goes into markersToChange', () {
      final original = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(31.23, 121.47),
      );
      final updated = original.copyWith(positionParam: const LatLng(32.0, 120.0));
      final updates = MarkerUpdates.from({original}, {updated});
      final json = updates.toJson();

      final toChange = json['markersToChange'] as List;
      expect(toChange, hasLength(1));
      expect((toChange[0] as Map)['markerId'], equals('m1'));
    });

    test('unchanged marker does not appear in any update list', () {
      final marker = Marker(
        markerId: const MarkerId('m1'),
        position: const LatLng(31.23, 121.47),
      );
      final updates = MarkerUpdates.from({marker}, {marker});
      final json = updates.toJson();

      expect((json['markersToAdd'] as List), isEmpty);
      expect((json['markersToChange'] as List), isEmpty);
      expect((json['markerIdsToRemove'] as List), isEmpty);
    });

    test('toJson contains required keys for native handler', () {
      final updates = MarkerUpdates.from({}, {});
      final json = updates.toJson();

      expect(json.containsKey('markersToAdd'), isTrue);
      expect(json.containsKey('markersToChange'), isTrue);
      expect(json.containsKey('markerIdsToRemove'), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PolylineUpdates — payload for polylines#update channel call
  // ─────────────────────────────────────────────────────────────────────────

  group('PolylineUpdates channel contract (polylines#update payload)', () {
    test('new polyline goes into polylinesToAdd', () {
      final polyline = Polyline(
        polylineId: const PolylineId('r1'),
        points: const [LatLng(31.23, 121.47), LatLng(31.25, 121.49)],
      );
      final updates = PolylineUpdates.from({}, {polyline});
      final json = updates.toJson();

      final toAdd = json['polylinesToAdd'] as List;
      expect(toAdd, hasLength(1));
      expect((toAdd[0] as Map)['polylineId'], equals('r1'));
    });

    test('removed polyline id goes into polylineIdsToRemove', () {
      final polyline = Polyline(polylineId: const PolylineId('r1'));
      final updates = PolylineUpdates.from({polyline}, {});
      final json = updates.toJson();

      expect((json['polylineIdsToRemove'] as List), contains('r1'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PolygonUpdates — payload for polygons#update channel call
  // ─────────────────────────────────────────────────────────────────────────

  group('PolygonUpdates channel contract (polygons#update payload)', () {
    test('new polygon goes into polygonsToAdd', () {
      final polygon = Polygon(
        polygonId: const PolygonId('a1'),
        points: const [LatLng(31.0, 121.0), LatLng(32.0, 121.0)],
      );
      final updates = PolygonUpdates.from({}, {polygon});
      final json = updates.toJson();

      final toAdd = json['polygonsToAdd'] as List;
      expect(toAdd, hasLength(1));
      expect((toAdd[0] as Map)['polygonId'], equals('a1'));
    });

    test('removed polygon id goes into polygonIdsToRemove', () {
      final polygon = Polygon(polygonId: const PolygonId('a1'));
      final updates = PolygonUpdates.from({polygon}, {});
      final json = updates.toJson();

      expect((json['polygonIdsToRemove'] as List), contains('a1'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CircleUpdates — payload for circles#update channel call
  // ─────────────────────────────────────────────────────────────────────────

  group('CircleUpdates channel contract (circles#update payload)', () {
    test('new circle goes into circlesToAdd', () {
      final circle = Circle(
        circleId: const CircleId('c1'),
        center: const LatLng(31.23, 121.47),
        radius: 500,
      );
      final updates = CircleUpdates.from({}, {circle});
      final json = updates.toJson();

      final toAdd = json['circlesToAdd'] as List;
      expect(toAdd, hasLength(1));
      expect((toAdd[0] as Map)['circleId'], equals('c1'));
    });

    test('removed circle id goes into circleIdsToRemove', () {
      final circle = Circle(
        circleId: const CircleId('c1'),
        center: const LatLng(31.23, 121.47),
        radius: 500,
      );
      final updates = CircleUpdates.from({circle}, {});
      final json = updates.toJson();

      expect((json['circleIdsToRemove'] as List), contains('c1'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AutonaviController — verifies RPC method names and argument shapes
  // ─────────────────────────────────────────────────────────────────────────

  group('AutonaviController channel contract', () {
    late List<MethodCall> log;
    const channelName = 'plugins.autonavi.flutter/amap_map_0';

    setUp(() {
      log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          log.add(call);
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        null,
      );
    });

    test('moveCamera sends map#moveCamera with newLatLng payload', () async {
      final controller = AutonaviController.init(0);
      await controller.moveCamera(
        CameraUpdate.newLatLng(const LatLng(31.23, 121.47)),
      );

      expect(log, hasLength(1));
      expect(log.first.method, equals('map#moveCamera'));
      final args = log.first.arguments as Map;
      expect(args['newLatLng'], equals({'latitude': 31.23, 'longitude': 121.47}));
    });

    test('animateCamera sends map#animateCamera', () async {
      final controller = AutonaviController.init(0);
      await controller.animateCamera(
        CameraUpdate.newLatLng(const LatLng(31.23, 121.47)),
      );

      expect(log, hasLength(1));
      expect(log.first.method, equals('map#animateCamera'));
    });

    test('showMarkerInfoWindow sends markers#showInfoWindow with markerId', () async {
      final controller = AutonaviController.init(0);
      await controller.showMarkerInfoWindow(const MarkerId('m-abc'));

      expect(log, hasLength(1));
      expect(log.first.method, equals('markers#showInfoWindow'));
      expect(
        (log.first.arguments as Map)['markerId'],
        equals('m-abc'),
      );
    });

    test('hideMarkerInfoWindow sends markers#hideInfoWindow with markerId', () async {
      final controller = AutonaviController.init(0);
      await controller.hideMarkerInfoWindow(const MarkerId('m-abc'));

      expect(log, hasLength(1));
      expect(log.first.method, equals('markers#hideInfoWindow'));
      expect(
        (log.first.arguments as Map)['markerId'],
        equals('m-abc'),
      );
    });

    test('convertFromWGS84 sends coordinate#convertFromWGS84 with lat/lng', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          log.add(call);
          // Return a valid LatLng map so the controller can parse it.
          return {'latitude': 31.24, 'longitude': 121.48};
        },
      );

      final controller = AutonaviController.init(0);
      await controller.convertFromWGS84(const LatLng(31.23, 121.47));

      expect(log, hasLength(1));
      expect(log.first.method, equals('coordinate#convertFromWGS84'));
      expect(
        log.first.arguments,
        equals({'latitude': 31.23, 'longitude': 121.47}),
      );
    });
  });
}
