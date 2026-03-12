/// An administrative district returned from a district search.
class DistrictItem {
  const DistrictItem({
    required this.name,
    this.adCode,
    this.cityCode,
    this.level,
    this.latitude,
    this.longitude,
    this.districts = const [],
  });

  final String name;
  final String? adCode;
  final String? cityCode;

  /// Administrative level: country, province, city, district, street.
  final String? level;
  final double? latitude;
  final double? longitude;

  /// Child districts.
  final List<DistrictItem> districts;

  factory DistrictItem.fromMap(Map<dynamic, dynamic> map) => DistrictItem(
        name: map['name'] as String? ?? '',
        adCode: map['adCode'] as String?,
        cityCode: map['cityCode'] as String?,
        level: map['level'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        districts: (map['districts'] as List? ?? [])
            .map((d) => DistrictItem.fromMap(d as Map))
            .toList(),
      );

  @override
  String toString() =>
      'DistrictItem(name: $name, level: $level, adCode: $adCode)';
}
