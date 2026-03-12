import 'package:flutter/services.dart';

import 'models/poi_item.dart';
import 'models/regeocode_result.dart';
import 'models/route_plan_result.dart';
import 'models/district_item.dart';

/// Latitude/longitude coordinate for search queries.
/// Mirrors the type from autonavi_maps_flutter but kept independent
/// to avoid a package dependency.
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  Map<String, double> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// AutoNavi search services.
///
/// Example:
/// ```dart
/// // POI search
/// final result = await AutonaviSearch.searchKeyword(
///   keyword: '咖啡',
///   city: '上海',
/// );
///
/// // Route planning
/// final route = await AutonaviSearch.drivingRoute(
///   origin: LatLng(31.224, 121.469),
///   destination: LatLng(31.197, 121.481),
/// );
/// ```
class AutonaviSearch {
  static const _channel = MethodChannel('plugins.autonavi.flutter/search');

  /// POI keyword search.
  static Future<PoiSearchResult> searchKeyword({
    required String keyword,
    required String city,
    String? types,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _channel.invokeMethod<Map>('search#keyword', {
      'keyword': keyword,
      'city': city,
      if (types != null) 'types': types,
      'page': page,
      'pageSize': pageSize,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'search#keyword returned null',
      );
    }
    return PoiSearchResult.fromMap(result);
  }

  /// POI nearby search.
  static Future<PoiSearchResult> searchNearby({
    required LatLng center,
    required int radiusMeters,
    String? keyword,
    String? types,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _channel.invokeMethod<Map>('search#nearby', {
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radiusMeters,
      if (keyword != null) 'keyword': keyword,
      if (types != null) 'types': types,
      'page': page,
      'pageSize': pageSize,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'search#nearby returned null',
      );
    }
    return PoiSearchResult.fromMap(result);
  }

  /// Reverse geocoding: coordinate → address.
  static Future<RegeocodeResult> regeocode(LatLng position) async {
    final result = await _channel.invokeMethod<Map>('search#regeocode', {
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'search#regeocode returned null',
      );
    }
    return RegeocodeResult.fromMap(result);
  }

  /// Forward geocoding: address → coordinate(s).
  static Future<List<GeocodeResult>> geocode({
    required String address,
    String? city,
  }) async {
    final result = await _channel.invokeMethod<List>('search#geocode', {
      'address': address,
      if (city != null) 'city': city,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'search#geocode returned null',
      );
    }
    return result.map((e) => GeocodeResult.fromMap(e as Map)).toList();
  }

  /// Driving route planning.
  static Future<DrivingRouteResult> drivingRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final result = await _channel.invokeMethod<Map>('route#driving', {
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'waypoints': waypoints.map((p) => p.toJson()).toList(),
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'route#driving returned null',
      );
    }
    return DrivingRouteResult.fromMap(result);
  }

  /// Walking route planning.
  static Future<WalkingRouteResult> walkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final result = await _channel.invokeMethod<Map>('route#walking', {
      'origin': origin.toJson(),
      'destination': destination.toJson(),
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'route#walking returned null',
      );
    }
    return WalkingRouteResult.fromMap(result);
  }

  /// Administrative district query.
  ///
  /// [keywords] — district name (e.g., "北京").
  /// [level] — depth: 1=province, 2=city, 3=district (default), 4=street.
  static Future<List<DistrictItem>> searchDistrict({
    required String keywords,
    int level = 3,
  }) async {
    final result = await _channel.invokeMethod<List>('search#district', {
      'keywords': keywords,
      'level': level,
    });
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'search#district returned null',
      );
    }
    return result.map((e) => DistrictItem.fromMap(e as Map)).toList();
  }
}
