import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'latlng.dart';

/// Uniquely identifies a [Polyline] on a map.
@immutable
class PolylineId {
  const PolylineId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is PolylineId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PolylineId($value)';
}

/// Draws a line through geographical locations on the map.
@immutable
class Polyline {
  const Polyline({
    required this.polylineId,
    this.consumeTapEvents = false,
    this.color = const Color(0xFF000000),
    this.endCap = Cap.buttCap,
    this.geodesic = false,
    this.jointType = JointType.mitered,
    this.points = const <LatLng>[],
    this.startCap = Cap.buttCap,
    this.visible = true,
    this.width = 10,
    this.zIndex = 0,
    this.onTap,
  });

  final PolylineId polylineId;
  final bool consumeTapEvents;
  final Color color;
  final Cap endCap;
  final bool geodesic;
  final JointType jointType;
  final List<LatLng> points;
  final Cap startCap;
  final bool visible;
  final int width;
  final int zIndex;
  final VoidCallback? onTap;

  Map<String, dynamic> toJson() => {
        'polylineId': polylineId.value,
        'consumeTapEvents': consumeTapEvents,
        'color': color.value,
        'geodesic': geodesic,
        'jointType': jointType.value,
        'points': points.map((p) => p.toJson()).toList(),
        'visible': visible,
        'width': width,
        'zIndex': zIndex,
      };

  @override
  bool operator ==(Object other) =>
      other is Polyline && other.polylineId == polylineId;

  @override
  int get hashCode => polylineId.hashCode;
}

/// Cap that can be applied to the start or end vertex of a [Polyline].
enum Cap {
  buttCap,
  roundCap,
  squareCap,
}

/// Joint type for a [Polyline].
enum JointType {
  mitered(0),
  bevel(1),
  round(2);

  const JointType(this.value);
  final int value;
}
