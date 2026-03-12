import 'package:flutter_test/flutter_test.dart';
import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

void main() {
  group('LatLng', () {
    test('creates with latitude and longitude', () {
      const latlng = LatLng(39.909187, 116.397451);
      expect(latlng.latitude, 39.909187);
      expect(latlng.longitude, 116.397451);
    });

    test('toJson produces correct map', () {
      const latlng = LatLng(39.909187, 116.397451);
      final json = latlng.toJson();
      expect(json['latitude'], 39.909187);
      expect(json['longitude'], 116.397451);
    });

    test('fromJson parses correctly', () {
      final latlng = LatLng.fromJson({
        'latitude': 39.909187,
        'longitude': 116.397451,
      });
      expect(latlng.latitude, 39.909187);
      expect(latlng.longitude, 116.397451);
    });

    test('equality works', () {
      const a = LatLng(1.0, 2.0);
      const b = LatLng(1.0, 2.0);
      const c = LatLng(3.0, 4.0);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = LatLng(1.0, 2.0);
      const b = LatLng(1.0, 2.0);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString produces readable output', () {
      const latlng = LatLng(1.0, 2.0);
      expect(latlng.toString(), contains('1.0'));
      expect(latlng.toString(), contains('2.0'));
    });
  });
}
