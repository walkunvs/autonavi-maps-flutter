import 'latlng.dart';

/// The position of the map camera.
class CameraPosition {
  const CameraPosition({
    required this.target,
    this.bearing = 0.0,
    this.tilt = 0.0,
    this.zoom = 10.0,
  });

  /// The camera's bearing in degrees, measured clockwise from north.
  final double bearing;

  /// The geographic location that the camera is pointing at.
  final LatLng target;

  /// The angle, in degrees, of the camera from the nadir (directly facing the Earth).
  final double tilt;

  /// Zoom level (typically 3-20 for AutoNavi).
  final double zoom;

  Map<String, dynamic> toJson() => {
        'bearing': bearing,
        'target': target.toJson(),
        'tilt': tilt,
        'zoom': zoom,
      };

  factory CameraPosition.fromJson(Map<dynamic, dynamic> json) => CameraPosition(
        bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
        target: LatLng.fromJson(json['target'] as Map),
        tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
        zoom: (json['zoom'] as num?)?.toDouble() ?? 10.0,
      );

  @override
  String toString() =>
      'CameraPosition(target: $target, zoom: $zoom, bearing: $bearing, tilt: $tilt)';

  @override
  bool operator ==(Object other) =>
      other is CameraPosition &&
      other.bearing == bearing &&
      other.target == target &&
      other.tilt == tilt &&
      other.zoom == zoom;

  @override
  int get hashCode => Object.hash(bearing, target, tilt, zoom);
}
