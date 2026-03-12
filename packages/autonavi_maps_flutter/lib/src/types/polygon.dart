import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'latlng.dart';

/// Uniquely identifies a [Polygon] on a map.
@immutable
class PolygonId {
  const PolygonId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is PolygonId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PolygonId($value)';
}

/// A polygon drawn on the map.
@immutable
class Polygon {
  const Polygon({
    required this.polygonId,
    this.consumeTapEvents = false,
    this.fillColor = const Color(0x00000000),
    this.geodesic = false,
    this.points = const <LatLng>[],
    this.holes = const <List<LatLng>>[],
    this.strokeColor = const Color(0xFF000000),
    this.strokeWidth = 10,
    this.visible = true,
    this.zIndex = 0,
    this.onTap,
  });

  final PolygonId polygonId;
  final bool consumeTapEvents;
  final Color fillColor;
  final bool geodesic;
  final List<LatLng> points;
  final List<List<LatLng>> holes;
  final Color strokeColor;
  final int strokeWidth;
  final bool visible;
  final int zIndex;
  final VoidCallback? onTap;

  Map<String, dynamic> toJson() => {
        'polygonId': polygonId.value,
        'consumeTapEvents': consumeTapEvents,
        'fillColor': fillColor.value,
        'geodesic': geodesic,
        'points': points.map((p) => p.toJson()).toList(),
        'holes': holes
            .map((hole) => hole.map((p) => p.toJson()).toList())
            .toList(),
        'strokeColor': strokeColor.value,
        'strokeWidth': strokeWidth,
        'visible': visible,
        'zIndex': zIndex,
      };

  @override
  bool operator ==(Object other) =>
      other is Polygon &&
      other.polygonId == polygonId &&
      other.consumeTapEvents == consumeTapEvents &&
      other.fillColor == fillColor &&
      other.geodesic == geodesic &&
      listEquals(other.points, points) &&
      other.holes.length == holes.length &&
      _holesEqual(other.holes, holes) &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible &&
      other.zIndex == zIndex;

  static bool _holesEqual(List<List<LatLng>> a, List<List<LatLng>> b) {
    for (int i = 0; i < a.length; i++) {
      if (!listEquals(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        polygonId,
        consumeTapEvents,
        fillColor,
        geodesic,
        Object.hashAll(points),
        Object.hashAll(holes.map(Object.hashAll)),
        strokeColor,
        strokeWidth,
        visible,
        zIndex,
      );
}
