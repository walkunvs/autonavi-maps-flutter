import '../types/polyline.dart';

/// A set of [Polyline] update operations to be applied to the map.
class PolylineUpdates {
  PolylineUpdates.from(Set<Polyline> previous, Set<Polyline> current) {
    final previousById = <PolylineId, Polyline>{
      for (final p in previous) p.polylineId: p,
    };
    final currentById = <PolylineId, Polyline>{
      for (final p in current) p.polylineId: p,
    };

    final _toAdd = <Polyline>{};
    final _toChange = <Polyline>{};
    final _idsToRemove = <PolylineId>{};

    for (final polyline in current) {
      final prev = previousById[polyline.polylineId];
      if (prev == null) {
        _toAdd.add(polyline);
      } else if (polyline != prev) {
        _toChange.add(polyline);
      }
    }

    for (final id in previousById.keys) {
      if (!currentById.containsKey(id)) {
        _idsToRemove.add(id);
      }
    }

    polylinesToAdd = Set.unmodifiable(_toAdd);
    polylinesToChange = Set.unmodifiable(_toChange);
    polylineIdsToRemove = Set.unmodifiable(_idsToRemove);
  }

  late final Set<Polyline> polylinesToAdd;
  late final Set<Polyline> polylinesToChange;
  late final Set<PolylineId> polylineIdsToRemove;

  Map<String, dynamic> toJson() => {
        'polylinesToAdd': polylinesToAdd.map((p) => p.toJson()).toList(),
        'polylinesToChange': polylinesToChange.map((p) => p.toJson()).toList(),
        'polylineIdsToRemove':
            polylineIdsToRemove.map((id) => id.value).toList(),
      };
}
