/// A geographic coordinate using the GCJ-02 coordinate system (Mars Coordinates)
/// used by AutoNavi maps.
class LatLng {
  const LatLng(this.latitude, this.longitude);

  /// The latitude in degrees, in the range [-90, 90].
  final double latitude;

  /// The longitude in degrees, in the range [-180, 180].
  final double longitude;

  Map<String, double> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LatLng.fromJson(Map<dynamic, dynamic> json) => LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
