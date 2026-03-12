import '../types/polygon.dart';

/// A set of [Polygon] update operations to be applied to the map.
class PolygonUpdates {
  PolygonUpdates.from(Set<Polygon> previous, Set<Polygon> current) {
    final previousById = <PolygonId, Polygon>{
      for (final p in previous) p.polygonId: p,
    };
    final currentById = <PolygonId, Polygon>{
      for (final p in current) p.polygonId: p,
    };

    final _toAdd = <Polygon>{};
    final _toChange = <Polygon>{};
    final _idsToRemove = <PolygonId>{};

    for (final polygon in current) {
      final prev = previousById[polygon.polygonId];
      if (prev == null) {
        _toAdd.add(polygon);
      } else if (polygon != prev) {
        _toChange.add(polygon);
      }
    }

    for (final id in previousById.keys) {
      if (!currentById.containsKey(id)) {
        _idsToRemove.add(id);
      }
    }

    polygonsToAdd = Set.unmodifiable(_toAdd);
    polygonsToChange = Set.unmodifiable(_toChange);
    polygonIdsToRemove = Set.unmodifiable(_idsToRemove);
  }

  late final Set<Polygon> polygonsToAdd;
  late final Set<Polygon> polygonsToChange;
  late final Set<PolygonId> polygonIdsToRemove;

  Map<String, dynamic> toJson() => {
        'polygonsToAdd': polygonsToAdd.map((p) => p.toJson()).toList(),
        'polygonsToChange': polygonsToChange.map((p) => p.toJson()).toList(),
        'polygonIdsToRemove':
            polygonIdsToRemove.map((id) => id.value).toList(),
      };
}
