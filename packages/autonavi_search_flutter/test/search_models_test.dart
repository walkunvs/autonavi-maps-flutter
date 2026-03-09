import 'package:flutter_test/flutter_test.dart';
import 'package:autonavi_search_flutter/autonavi_search_flutter.dart';

void main() {
  group('PoiItem', () {
    test('fromMap parses required fields', () {
      final poi = PoiItem.fromMap({
        'poiId': 'B000A8UZ0A',
        'title': '天安门',
      });
      expect(poi.poiId, 'B000A8UZ0A');
      expect(poi.title, '天安门');
      expect(poi.latitude, isNull);
    });

    test('fromMap parses all fields', () {
      final poi = PoiItem.fromMap({
        'poiId': 'B000A8UZ0A',
        'title': '天安门',
        'typeDes': '著名景点',
        'latitude': 39.909187,
        'longitude': 116.397451,
        'address': '北京市东城区天安门广场',
        'cityName': '北京市',
        'distance': 500.0,
      });
      expect(poi.latitude, 39.909187);
      expect(poi.cityName, '北京市');
      expect(poi.distance, 500.0);
    });
  });

  group('PoiSearchResult', () {
    test('fromMap parses result list', () {
      final result = PoiSearchResult.fromMap({
        'pois': [
          {'poiId': '1', 'title': 'POI A'},
          {'poiId': '2', 'title': 'POI B'},
        ],
        'totalCount': 100,
        'pageCount': 5,
        'pageNum': 1,
      });
      expect(result.pois.length, 2);
      expect(result.totalCount, 100);
      expect(result.pageCount, 5);
    });
  });

  group('RegeocodeResult', () {
    test('fromMap parses address fields', () {
      final result = RegeocodeResult.fromMap({
        'formattedAddress': '北京市东城区天安门广场',
        'city': '北京市',
        'district': '东城区',
      });
      expect(result.formattedAddress, '北京市东城区天安门广场');
      expect(result.city, '北京市');
    });
  });

  group('DrivingRouteResult', () {
    test('fromMap parses empty paths', () {
      final result = DrivingRouteResult.fromMap({'paths': []});
      expect(result.paths, isEmpty);
    });

    test('fromMap parses route paths', () {
      final result = DrivingRouteResult.fromMap({
        'paths': [
          {
            'distance': 10000.0,
            'duration': 1200.0,
            'steps': [],
          }
        ],
      });
      expect(result.paths.length, 1);
      expect(result.paths.first.distance, 10000.0);
      expect(result.paths.first.duration, 1200.0);
    });
  });

  group('DistrictItem', () {
    test('fromMap parses district with children', () {
      final item = DistrictItem.fromMap({
        'name': '北京市',
        'adCode': '110000',
        'level': 'province',
        'districts': [
          {'name': '东城区', 'adCode': '110101', 'level': 'district'},
        ],
      });
      expect(item.name, '北京市');
      expect(item.level, 'province');
      expect(item.districts.length, 1);
      expect(item.districts.first.name, '东城区');
    });
  });
}
