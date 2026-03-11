import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'types/latlng.dart';
import 'types/camera_position.dart';
import 'types/camera_update.dart';
import 'types/marker.dart';
import 'types/screen_coordinate.dart';

/// Controller for a single [AutonaviWidget] instance.
///
/// Used to programmatically control the camera, query map state,
/// and manage marker info windows.
class AutonaviController {
  AutonaviController._(MethodChannel channel) : _channel = channel;

  final MethodChannel _channel;

  static AutonaviController init(int mapId) => AutonaviController._(
        MethodChannel('plugins.autonavi.flutter/amap_map_$mapId'),
      );

  /// Moves the camera to [update] without animation.
  Future<void> moveCamera(CameraUpdate update) =>
      _channel.invokeMethod('map#moveCamera', update.toJson());

  /// Animates the camera to [update].
  Future<void> animateCamera(CameraUpdate update) =>
      _channel.invokeMethod('map#animateCamera', update.toJson());

  /// Returns the current camera position.
  Future<CameraPosition?> getCameraPosition() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('map#getCameraPosition');
    return result == null ? null : CameraPosition.fromJson(result);
  }

  /// Returns the geographic coordinate corresponding to [coordinate] on screen.
  Future<LatLng?> getLatLng(ScreenCoordinate coordinate) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'map#getLatLng',
      coordinate.toJson(),
    );
    return result == null ? null : LatLng.fromJson(result);
  }

  /// Converts [latLng] to screen coordinates.
  Future<ScreenCoordinate?> getScreenCoordinate(LatLng latLng) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'map#getScreenCoordinate',
      latLng.toJson(),
    );
    return result == null ? null : ScreenCoordinate.fromJson(result);
  }

  /// Returns a screenshot of the current map view as PNG bytes.
  Future<Uint8List?> takeSnapshot() =>
      _channel.invokeMethod<Uint8List>('map#takeSnapshot');

  /// Shows the info window for the marker with [markerId].
  Future<void> showMarkerInfoWindow(MarkerId markerId) =>
      _channel.invokeMethod('markers#showInfoWindow', {'markerId': markerId.value});

  /// Hides the info window for the marker with [markerId].
  Future<void> hideMarkerInfoWindow(MarkerId markerId) =>
      _channel.invokeMethod('markers#hideInfoWindow', {'markerId': markerId.value});

  /// Returns whether the info window for the marker with [markerId] is shown.
  Future<bool> isMarkerInfoWindowShown(MarkerId markerId) async {
    final result = await _channel.invokeMethod<bool>(
      'markers#isInfoWindowShown',
      {'markerId': markerId.value},
    );
    return result ?? false;
  }

  /// Converts a WGS-84 coordinate to GCJ-02 (AutoNavi's coordinate system).
  Future<LatLng> convertFromWGS84(LatLng wgs84) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'coordinate#convertFromWGS84',
      wgs84.toJson(),
    );
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'coordinate#convertFromWGS84 returned null',
      );
    }
    return LatLng.fromJson(result);
  }
}
