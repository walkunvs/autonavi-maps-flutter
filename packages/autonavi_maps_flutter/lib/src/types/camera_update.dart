import 'latlng.dart';
import 'latlng_bounds.dart';
import 'camera_position.dart';

/// Defines a camera move, supporting both animate and move.
class CameraUpdate {
  const CameraUpdate._(this._json);

  final Map<String, dynamic> _json;

  /// Returns a camera update that moves the camera to the specified position.
  static CameraUpdate newCameraPosition(CameraPosition cameraPosition) =>
      CameraUpdate._({'newCameraPosition': cameraPosition.toJson()});

  /// Returns a camera update that moves the camera target to the specified coordinate.
  static CameraUpdate newLatLng(LatLng latLng) =>
      CameraUpdate._({'newLatLng': latLng.toJson()});

  /// Returns a camera update that transforms the camera so that
  /// the specified coordinate is in the center of the map at the given zoom level.
  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) =>
      CameraUpdate._({
        'newLatLngZoom': {'latLng': latLng.toJson(), 'zoom': zoom},
      });

  /// Returns a camera update that transforms the camera so that
  /// the specified bounds are centered on screen at the greatest possible zoom level.
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) =>
      CameraUpdate._({
        'newLatLngBounds': {
          'bounds': bounds.toJson(),
          'padding': padding,
        },
      });

  /// Returns a camera update that moves the camera to the specified zoom level.
  static CameraUpdate zoomTo(double zoom) =>
      CameraUpdate._({'zoomTo': zoom});

  /// Returns a camera update that zooms the camera in by one step.
  static CameraUpdate zoomIn() => const CameraUpdate._({'zoomIn': null});

  /// Returns a camera update that zooms the camera out by one step.
  static CameraUpdate zoomOut() => const CameraUpdate._({'zoomOut': null});

  /// Returns a camera update that adjusts the zoom level by the given amount.
  static CameraUpdate zoomBy(double amount) =>
      CameraUpdate._({'zoomBy': amount});

  /// Returns a camera update that scrolls the camera by the given distance in pixels.
  static CameraUpdate scrollBy(double dx, double dy) =>
      CameraUpdate._({'scrollBy': {'dx': dx, 'dy': dy}});

  Map<String, dynamic> toJson() => _json;
}
