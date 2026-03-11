import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'latlng.dart';

/// Uniquely identifies a [Circle] on a map.
@immutable
class CircleId {
  const CircleId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is CircleId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CircleId($value)';
}

/// A circle drawn on the map.
@immutable
class Circle {
  const Circle({
    required this.circleId,
    required this.center,
    required this.radius,
    this.consumeTapEvents = false,
    this.fillColor = const Color(0x00000000),
    this.strokeColor = const Color(0xFF000000),
    this.strokeWidth = 10,
    this.visible = true,
    this.zIndex = 0,
    this.onTap,
  });

  final CircleId circleId;
  final LatLng center;

  /// Radius of the circle in meters.
  final double radius;
  final bool consumeTapEvents;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;
  final bool visible;
  final int zIndex;
  final VoidCallback? onTap;

  Map<String, dynamic> toJson() => {
        'circleId': circleId.value,
        'center': center.toJson(),
        'radius': radius,
        'consumeTapEvents': consumeTapEvents,
        'fillColor': fillColor.value,
        'strokeColor': strokeColor.value,
        'strokeWidth': strokeWidth,
        'visible': visible,
        'zIndex': zIndex,
      };

  @override
  bool operator ==(Object other) =>
      other is Circle &&
      other.circleId == circleId &&
      other.center == center &&
      other.radius == radius &&
      other.consumeTapEvents == consumeTapEvents &&
      other.fillColor == fillColor &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible &&
      other.zIndex == zIndex;

  @override
  int get hashCode => Object.hash(
        circleId,
        center,
        radius,
        consumeTapEvents,
        fillColor,
        strokeColor,
        strokeWidth,
        visible,
        zIndex,
      );
}
