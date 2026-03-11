import 'package:flutter/foundation.dart';

import 'latlng.dart';
import 'bitmap_descriptor.dart';
import 'info_window.dart';

/// Uniquely identifies a [Marker] on a map.
@immutable
class MarkerId {
  const MarkerId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is MarkerId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MarkerId($value)';
}

/// Marks a geographic location on the map.
@immutable
class Marker {
  const Marker({
    required this.markerId,
    required this.position,
    this.alpha = 1.0,
    this.anchor = const Offset(0.5, 1.0),
    this.consumeTapEvents = false,
    this.draggable = false,
    this.flat = false,
    this.icon = BitmapDescriptor.defaultMarker,
    this.infoWindow = InfoWindow.noText,
    this.rotation = 0.0,
    this.visible = true,
    this.zIndex = 0.0,
    this.onTap,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
  });

  final MarkerId markerId;
  final LatLng position;
  final double alpha;
  final Offset anchor;
  final bool consumeTapEvents;
  final bool draggable;
  final bool flat;
  final BitmapDescriptor icon;
  final InfoWindow infoWindow;
  final double rotation;
  final bool visible;
  final double zIndex;
  final VoidCallback? onTap;
  final ValueChanged<LatLng>? onDragStart;
  final ValueChanged<LatLng>? onDrag;
  final ValueChanged<LatLng>? onDragEnd;

  Marker copyWith({
    LatLng? positionParam,
    double? alphaParam,
    Offset? anchorParam,
    bool? consumeTapEventsParam,
    bool? draggableParam,
    bool? flatParam,
    BitmapDescriptor? iconParam,
    InfoWindow? infoWindowParam,
    double? rotationParam,
    bool? visibleParam,
    double? zIndexParam,
    VoidCallback? onTapParam,
    ValueChanged<LatLng>? onDragStartParam,
    ValueChanged<LatLng>? onDragParam,
    ValueChanged<LatLng>? onDragEndParam,
  }) {
    return Marker(
      markerId: markerId,
      position: positionParam ?? position,
      alpha: alphaParam ?? alpha,
      anchor: anchorParam ?? anchor,
      consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
      draggable: draggableParam ?? draggable,
      flat: flatParam ?? flat,
      icon: iconParam ?? icon,
      infoWindow: infoWindowParam ?? infoWindow,
      rotation: rotationParam ?? rotation,
      visible: visibleParam ?? visible,
      zIndex: zIndexParam ?? zIndex,
      onTap: onTapParam ?? onTap,
      onDragStart: onDragStartParam ?? onDragStart,
      onDrag: onDragParam ?? onDrag,
      onDragEnd: onDragEndParam ?? onDragEnd,
    );
  }

  Map<String, dynamic> toJson() => {
        'markerId': markerId.value,
        'position': position.toJson(),
        'alpha': alpha,
        'anchor': {'dx': anchor.dx, 'dy': anchor.dy},
        'consumeTapEvents': consumeTapEvents,
        'draggable': draggable,
        'flat': flat,
        'icon': icon.toJson(),
        'infoWindow': infoWindow.toJson(),
        'rotation': rotation,
        'visible': visible,
        'zIndex': zIndex,
      };

  @override
  bool operator ==(Object other) =>
      other is Marker &&
      other.markerId == markerId &&
      other.position == position &&
      other.alpha == alpha &&
      other.anchor == anchor &&
      other.consumeTapEvents == consumeTapEvents &&
      other.draggable == draggable &&
      other.flat == flat &&
      other.rotation == rotation &&
      other.visible == visible &&
      other.zIndex == zIndex;

  @override
  int get hashCode => Object.hash(
        markerId,
        position,
        alpha,
        anchor,
        consumeTapEvents,
        draggable,
        flat,
        rotation,
        visible,
        zIndex,
      );
}
