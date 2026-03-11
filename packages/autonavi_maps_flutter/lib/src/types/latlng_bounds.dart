import 'latlng.dart';

/// An immutable class representing a latitude/longitude aligned rectangle.
class LatLngBounds {
  LatLngBounds({required this.southwest, required this.northeast})
      : assert(southwest.latitude <= northeast.latitude);

  /// The southwest corner of the rectangle.
  final LatLng southwest;

  /// The northeast corner of the rectangle.
  final LatLng northeast;

  bool contains(LatLng point) =>
      point.latitude >= southwest.latitude &&
      point.latitude <= northeast.latitude &&
      point.longitude >= southwest.longitude &&
      point.longitude <= northeast.longitude;

  LatLng get center => LatLng(
        (southwest.latitude + northeast.latitude) / 2,
        (southwest.longitude + northeast.longitude) / 2,
      );

  Map<String, dynamic> toJson() => {
        'southwest': southwest.toJson(),
        'northeast': northeast.toJson(),
      };

  factory LatLngBounds.fromJson(Map<dynamic, dynamic> json) => LatLngBounds(
        southwest: LatLng.fromJson(json['southwest'] as Map),
        northeast: LatLng.fromJson(json['northeast'] as Map),
      );

  @override
  String toString() =>
      'LatLngBounds(southwest: $southwest, northeast: $northeast)';

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds &&
      other.southwest == southwest &&
      other.northeast == northeast;

  @override
  int get hashCode => Object.hash(southwest, northeast);
}
