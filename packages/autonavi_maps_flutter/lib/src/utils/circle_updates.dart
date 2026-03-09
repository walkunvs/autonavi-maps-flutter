import '../types/circle.dart';

/// A set of [Circle] update operations to be applied to the map.
class CircleUpdates {
  CircleUpdates.from(Set<Circle> previous, Set<Circle> current) {
    final previousById = <CircleId, Circle>{
      for (final c in previous) c.circleId: c,
    };
    final currentById = <CircleId, Circle>{
      for (final c in current) c.circleId: c,
    };

    final _toAdd = <Circle>{};
    final _toChange = <Circle>{};
    final _idsToRemove = <CircleId>{};

    for (final circle in current) {
      final prev = previousById[circle.circleId];
      if (prev == null) {
        _toAdd.add(circle);
      } else if (circle != prev) {
        _toChange.add(circle);
      }
    }

    for (final id in previousById.keys) {
      if (!currentById.containsKey(id)) {
        _idsToRemove.add(id);
      }
    }

    circlesToAdd = Set.unmodifiable(_toAdd);
    circlesToChange = Set.unmodifiable(_toChange);
    circleIdsToRemove = Set.unmodifiable(_idsToRemove);
  }

  late final Set<Circle> circlesToAdd;
  late final Set<Circle> circlesToChange;
  late final Set<CircleId> circleIdsToRemove;

  Map<String, dynamic> toJson() => {
        'circlesToAdd': circlesToAdd.map((c) => c.toJson()).toList(),
        'circlesToChange': circlesToChange.map((c) => c.toJson()).toList(),
        'circleIdsToRemove':
            circleIdsToRemove.map((id) => id.value).toList(),
      };
}
