/// Common options for POI search queries.
class PoiSearchOptions {
  const PoiSearchOptions({
    this.types,
    this.page = 1,
    this.pageSize = 20,
  });

  /// POI type filter (AutoNavi type codes, e.g., "050100" for restaurants).
  final String? types;

  /// Page number (1-based).
  final int page;

  /// Number of results per page (1-50).
  final int pageSize;
}
