import 'dart:typed_data';

/// Defines a bitmap image for use as a marker icon.
class BitmapDescriptor {
  const BitmapDescriptor._(_BitmapDescriptorType type, dynamic data)
      : _type = type,
        _data = data;

  final _BitmapDescriptorType _type;
  final dynamic _data;

  /// The default marker icon provided by AutoNavi.
  static const BitmapDescriptor defaultMarker =
      BitmapDescriptor._(_BitmapDescriptorType.defaultMarker, null);

  /// Creates a [BitmapDescriptor] from a hue value in the range [0, 360).
  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    assert(hue >= 0.0 && hue < 360.0);
    return BitmapDescriptor._(_BitmapDescriptorType.defaultMarkerWithHue, hue);
  }

  /// Creates a [BitmapDescriptor] from a Flutter asset image.
  static BitmapDescriptor asset(
    String assetName, {
    double? imagePixelRatio,
    double? width,
    double? height,
  }) =>
      BitmapDescriptor._(_BitmapDescriptorType.asset, {
        'assetName': assetName,
        if (imagePixelRatio != null) 'imagePixelRatio': imagePixelRatio,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      });

  /// Creates a [BitmapDescriptor] from raw PNG bytes.
  static BitmapDescriptor bytes(Uint8List byteData) =>
      BitmapDescriptor._(_BitmapDescriptorType.bytes, byteData);

  Map<String, dynamic> toJson() {
    switch (_type) {
      case _BitmapDescriptorType.defaultMarker:
        return {'type': 'defaultMarker'};
      case _BitmapDescriptorType.defaultMarkerWithHue:
        return {'type': 'defaultMarkerWithHue', 'hue': _data as double};
      case _BitmapDescriptorType.asset:
        return {'type': 'asset', ...(_data as Map<String, dynamic>)};
      case _BitmapDescriptorType.bytes:
        return {'type': 'bytes', 'byteData': _data as Uint8List};
    }
  }
}

enum _BitmapDescriptorType {
  defaultMarker,
  defaultMarkerWithHue,
  asset,
  bytes,
}

/// Common hue values for use with [BitmapDescriptor.defaultMarkerWithHue].
class BitmapDescriptorHue {
  static const double red = 0.0;
  static const double orange = 30.0;
  static const double yellow = 60.0;
  static const double green = 120.0;
  static const double cyan = 180.0;
  static const double azure = 210.0;
  static const double blue = 240.0;
  static const double violet = 270.0;
  static const double magenta = 300.0;
  static const double rose = 330.0;
}
