/// The result of a reverse geocoding query (coordinate → address).
class RegeocodeResult {
  const RegeocodeResult({
    this.formattedAddress,
    this.country,
    this.province,
    this.city,
    this.cityCode,
    this.district,
    this.adCode,
    this.street,
    this.streetNumber,
    this.townCode,
    this.township,
  });

  final String? formattedAddress;
  final String? country;
  final String? province;
  final String? city;
  final String? cityCode;
  final String? district;
  final String? adCode;
  final String? street;
  final String? streetNumber;
  final String? townCode;
  final String? township;

  factory RegeocodeResult.fromMap(Map<dynamic, dynamic> map) => RegeocodeResult(
        formattedAddress: map['formattedAddress'] as String?,
        country: map['country'] as String?,
        province: map['province'] as String?,
        city: map['city'] as String?,
        cityCode: map['cityCode'] as String?,
        district: map['district'] as String?,
        adCode: map['adCode'] as String?,
        street: map['street'] as String?,
        streetNumber: map['streetNumber'] as String?,
        townCode: map['townCode'] as String?,
        township: map['township'] as String?,
      );

  @override
  String toString() => 'RegeocodeResult(address: $formattedAddress)';
}

/// The result of a forward geocoding query (address → coordinate).
class GeocodeResult {
  const GeocodeResult({
    this.formattedAddress,
    this.country,
    this.province,
    this.city,
    this.cityCode,
    this.district,
    this.adCode,
    this.latitude,
    this.longitude,
    this.level,
  });

  final String? formattedAddress;
  final String? country;
  final String? province;
  final String? city;
  final String? cityCode;
  final String? district;
  final String? adCode;
  final double? latitude;
  final double? longitude;
  final String? level;

  factory GeocodeResult.fromMap(Map<dynamic, dynamic> map) => GeocodeResult(
        formattedAddress: map['formattedAddress'] as String?,
        country: map['country'] as String?,
        province: map['province'] as String?,
        city: map['city'] as String?,
        cityCode: map['cityCode'] as String?,
        district: map['district'] as String?,
        adCode: map['adCode'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        level: map['level'] as String?,
      );

  @override
  String toString() =>
      'GeocodeResult(address: $formattedAddress, lat: $latitude, lng: $longitude)';
}
