import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutonaviWidget', () {
    test('creates with required initialCameraPosition', () {
      const widget = AutonaviWidget(
        initialCameraPosition: CameraPosition(
          target: LatLng(39.909187, 116.397451),
          zoom: 12,
        ),
      );
      expect(widget.initialCameraPosition.zoom, 12.0);
      expect(widget.markers, isEmpty);
      expect(widget.polylines, isEmpty);
      expect(widget.polygons, isEmpty);
      expect(widget.circles, isEmpty);
      expect(widget.mapType, MapType.normal);
      expect(widget.compassEnabled, isTrue);
      expect(widget.trafficEnabled, isFalse);
      expect(widget.myLocationEnabled, isFalse);
    });
  });

  group('MinMaxZoomPreference', () {
    test('unbounded has null min and max', () {
      const pref = MinMaxZoomPreference.unbounded;
      expect(pref.minZoom, isNull);
      expect(pref.maxZoom, isNull);
    });

    test('toJson omits null values', () {
      const pref = MinMaxZoomPreference(5.0, 18.0);
      final json = pref.toJson();
      expect(json['minZoom'], 5.0);
      expect(json['maxZoom'], 18.0);
    });
  });
}
