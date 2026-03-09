import 'package:flutter_test/flutter_test.dart';
import 'package:autonavi_location_flutter/autonavi_location_flutter.dart';

void main() {
  group('LocationResult', () {
    test('fromMap parses required fields', () {
      final result = LocationResult.fromMap({
        'latitude': 39.909187,
        'longitude': 116.397451,
        'accuracy': 10.0,
      });
      expect(result.latitude, 39.909187);
      expect(result.longitude, 116.397451);
      expect(result.accuracy, 10.0);
      expect(result.city, isNull);
    });

    test('fromMap parses all optional fields', () {
      final result = LocationResult.fromMap({
        'latitude': 39.909187,
        'longitude': 116.397451,
        'accuracy': 10.0,
        'altitude': 50.0,
        'speed': 5.0,
        'heading': 90.0,
        'timestamp': 1700000000000,
        'address': '北京市东城区天安门',
        'city': '北京市',
        'province': '北京市',
        'district': '东城区',
        'poiName': '天安门',
      });
      expect(result.altitude, 50.0);
      expect(result.speed, 5.0);
      expect(result.heading, 90.0);
      expect(result.city, '北京市');
      expect(result.poiName, '天安门');
      expect(result.timestamp, isNotNull);
    });

    test('toString contains coordinates', () {
      final result = LocationResult.fromMap({
        'latitude': 1.0,
        'longitude': 2.0,
        'accuracy': 5.0,
      });
      expect(result.toString(), contains('1.0'));
      expect(result.toString(), contains('2.0'));
    });
  });

  group('LocationOptions', () {
    test('defaults are sensible', () {
      const options = LocationOptions();
      expect(options.accuracy, LocationAccuracy.high);
      expect(options.intervalMs, 2000);
      expect(options.needAddress, isTrue);
      expect(options.onceLocation, isFalse);
    });

    test('toJson includes all fields', () {
      const options = LocationOptions(
        accuracy: LocationAccuracy.best,
        intervalMs: 5000,
        distanceFilter: 10.0,
        needAddress: false,
        onceLocation: true,
      );
      final json = options.toJson();
      expect(json['accuracy'], LocationAccuracy.best.index);
      expect(json['intervalMs'], 5000);
      expect(json['distanceFilter'], 10.0);
      expect(json['needAddress'], false);
      expect(json['onceLocation'], true);
    });
  });
}
