/// A single POI (Point of Interest) returned from a search.
class PoiItem {
  const PoiItem({
    required this.poiId,
    required this.title,
    this.typeDes,
    this.typeCode,
    this.latitude,
    this.longitude,
    this.address,
    this.tel,
    this.distance,
    this.cityName,
    this.adName,
    this.snippet,
  });

  final String poiId;
  final String title;
  final String? typeDes;
  final String? typeCode;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? tel;

  /// Distance from search center in meters (for nearby searches).
  final double? distance;
  final String? cityName;
  final String? adName;
  final String? snippet;

  factory PoiItem.fromMap(Map<dynamic, dynamic> map) => PoiItem(
        poiId: map['poiId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        typeDes: map['typeDes'] as String?,
        typeCode: map['typeCode'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        address: map['address'] as String?,
        tel: map['tel'] as String?,
        distance: (map['distance'] as num?)?.toDouble(),
        cityName: map['cityName'] as String?,
        adName: map['adName'] as String?,
        snippet: map['snippet'] as String?,
      );

  @override
  String toString() => 'PoiItem(title: $title, address: $address)';
}

/// The result of a POI search query.
class PoiSearchResult {
  const PoiSearchResult({
    required this.pois,
    required this.totalCount,
    required this.pageCount,
    required this.pageNum,
  });

  final List<PoiItem> pois;
  final int totalCount;
  final int pageCount;
  final int pageNum;

  factory PoiSearchResult.fromMap(Map<dynamic, dynamic> map) => PoiSearchResult(
        pois: (map['pois'] as List? ?? [])
            .map((e) => PoiItem.fromMap(e as Map))
            .toList(),
        totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
        pageCount: (map['pageCount'] as num?)?.toInt() ?? 0,
        pageNum: (map['pageNum'] as num?)?.toInt() ?? 1,
      );
}
