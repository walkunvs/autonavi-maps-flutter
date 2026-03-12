import 'package:flutter_test/flutter_test.dart';
import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

void main() {
  group('CameraPosition', () {
    const target = LatLng(39.909187, 116.397451);

    test('creates with required target', () {
      const pos = CameraPosition(target: target);
      expect(pos.target, target);
      expect(pos.bearing, 0.0);
      expect(pos.tilt, 0.0);
      expect(pos.zoom, 10.0);
    });

    test('creates with all parameters', () {
      const pos = CameraPosition(
        target: target,
        bearing: 45.0,
        tilt: 30.0,
        zoom: 15.0,
      );
      expect(pos.bearing, 45.0);
      expect(pos.tilt, 30.0);
      expect(pos.zoom, 15.0);
    });

    test('toJson produces correct map', () {
      const pos = CameraPosition(target: target, zoom: 12.0);
      final json = pos.toJson();
      expect(json['zoom'], 12.0);
      expect((json['target'] as Map)['latitude'], target.latitude);
    });

    test('fromJson parses correctly', () {
      final pos = CameraPosition.fromJson({
        'target': {'latitude': 39.909187, 'longitude': 116.397451},
        'bearing': 45.0,
        'tilt': 30.0,
        'zoom': 15.0,
      });
      expect(pos.zoom, 15.0);
      expect(pos.bearing, 45.0);
    });

    test('equality works', () {
      const a = CameraPosition(target: target, zoom: 12.0);
      const b = CameraPosition(target: target, zoom: 12.0);
      const c = CameraPosition(target: target, zoom: 14.0);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
