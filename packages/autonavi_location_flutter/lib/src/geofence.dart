import 'package:flutter/services.dart';

/// The status of a geofence event.
enum GeofenceStatus {
  /// Device entered the geofence.
  enter,

  /// Device exited the geofence.
  exit,

  /// Device is active inside the geofence.
  active,
}

/// A geofence event emitted when the device crosses a fence boundary.
class GeofenceEvent {
  const GeofenceEvent({
    required this.fenceId,
    required this.status,
    this.latitude,
    this.longitude,
  });

  final String fenceId;
  final GeofenceStatus status;
  final double? latitude;
  final double? longitude;

  factory GeofenceEvent.fromMap(Map<dynamic, dynamic> map) {
    final statusIndex = map['status'] as int? ?? 0;
    return GeofenceEvent(
      fenceId: map['fenceId'] as String,
      status: GeofenceStatus.values[statusIndex],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Manages geofences using the AutoNavi Location SDK.
class AutonaviGeofence {
  static const _channel =
      MethodChannel('plugins.autonavi.flutter/location_method');
  static const _eventChannel =
      EventChannel('plugins.autonavi.flutter/geofence_events');

  /// Stream of geofence crossing events.
  static Stream<GeofenceEvent> get onGeofenceEvent =>
      _eventChannel.receiveBroadcastStream().map(
            (e) => GeofenceEvent.fromMap(e as Map<dynamic, dynamic>),
          );

  /// Adds a circular geofence.
  ///
  /// [fenceId] — unique identifier for this fence.
  /// [latitude], [longitude] — center of the circle.
  /// [radiusMeters] — radius in meters.
  static Future<void> addCircularFence({
    required String fenceId,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) =>
      _channel.invokeMethod('geofence#addCircle', {
        'fenceId': fenceId,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
      });

  /// Removes the geofence with the given [fenceId].
  static Future<void> removeFence(String fenceId) =>
      _channel.invokeMethod('geofence#remove', {'fenceId': fenceId});

  /// Removes all geofences.
  static Future<void> removeAllFences() =>
      _channel.invokeMethod('geofence#removeAll');
}
