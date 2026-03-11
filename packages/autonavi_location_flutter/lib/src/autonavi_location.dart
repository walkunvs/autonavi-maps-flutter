import 'package:flutter/services.dart';

import 'location_options.dart';
import 'location_result.dart';

/// Access to AutoNavi location services.
///
/// Example:
/// ```dart
/// // Continuous location updates
/// AutonaviLocation.onLocationChanged.listen((result) {
///   print('${result.city} ${result.address}');
/// });
///
/// // Single location fix
/// final location = await AutonaviLocation.getLocation();
/// ```
class AutonaviLocation {
  static const _methodChannel =
      MethodChannel('plugins.autonavi.flutter/location_method');
  static const _eventChannel =
      EventChannel('plugins.autonavi.flutter/location');

  /// A broadcast stream of continuous location updates.
  ///
  /// The stream starts the location SDK when first listened to and stops it
  /// when all listeners cancel.
  static Stream<LocationResult> get onLocationChanged =>
      _eventChannel.receiveBroadcastStream().map(
            (e) => LocationResult.fromMap(e as Map<dynamic, dynamic>),
          );

  /// Performs a single location fix.
  ///
  /// [options] controls accuracy and whether address data is included.
  static Future<LocationResult> getLocation({
    LocationOptions options = const LocationOptions(onceLocation: true),
  }) async {
    final result = await _methodChannel.invokeMethod<Map>(
      'location#getOnce',
      options.toJson(),
    );
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'location#getOnce returned null',
      );
    }
    return LocationResult.fromMap(result);
  }

  /// Updates the options for the continuous location stream.
  ///
  /// Takes effect immediately if the stream is active.
  static Future<void> updateOptions(LocationOptions options) =>
      _methodChannel.invokeMethod(
        'location#updateOptions',
        options.toJson(),
      );
}
