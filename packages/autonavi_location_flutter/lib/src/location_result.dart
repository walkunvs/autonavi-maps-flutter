/// The result of a location query, including optional address information.
///
/// AutoNavi provides rich address fields (province, city, district, etc.)
/// that are not available in standard platform location APIs.
class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.timestamp,
    this.address,
    this.country,
    this.province,
    this.city,
    this.district,
    this.street,
    this.streetNum,
    this.cityCode,
    this.adCode,
    this.poiName,
    this.aoiName,
  });

  final double latitude;
  final double longitude;

  /// Accuracy in meters.
  final double accuracy;
  final double? altitude;

  /// Speed in meters per second.
  final double? speed;

  /// Heading/bearing in degrees from north.
  final double? heading;
  final DateTime? timestamp;

  /// Full formatted address string.
  final String? address;
  final String? country;
  final String? province;
  final String? city;
  final String? district;
  final String? street;
  final String? streetNum;
  final String? cityCode;
  final String? adCode;

  /// Name of the nearest POI.
  final String? poiName;

  /// Name of the AOI (Area of Interest) the location is in.
  final String? aoiName;

  factory LocationResult.fromMap(Map<dynamic, dynamic> map) => LocationResult(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        accuracy: (map['accuracy'] as num).toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble(),
        speed: (map['speed'] as num?)?.toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
        timestamp: map['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (map['timestamp'] as num).toInt())
            : null,
        address: map['address'] as String?,
        country: map['country'] as String?,
        province: map['province'] as String?,
        city: map['city'] as String?,
        district: map['district'] as String?,
        street: map['street'] as String?,
        streetNum: map['streetNum'] as String?,
        cityCode: map['cityCode'] as String?,
        adCode: map['adCode'] as String?,
        poiName: map['poiName'] as String?,
        aoiName: map['aoiName'] as String?,
      );

  @override
  String toString() =>
      'LocationResult(lat: $latitude, lng: $longitude, accuracy: ${accuracy}m'
      '${city != null ? ", city: $city" : ""}'
      '${address != null ? ", address: $address" : ""}'
      ')';
}
