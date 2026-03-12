import '../types/marker.dart';

/// A set of [Marker] update operations to be applied to the map.
class MarkerUpdates {
  MarkerUpdates.from(Set<Marker> previous, Set<Marker> current) {
    final previousByMarkerId = <MarkerId, Marker>{
      for (final marker in previous) marker.markerId: marker,
    };
    final currentByMarkerId = <MarkerId, Marker>{
      for (final marker in current) marker.markerId: marker,
    };

    final _markersToAdd = <Marker>{};
    final _markersToChange = <Marker>{};
    final _markerIdsToRemove = <MarkerId>{};

    for (final marker in current) {
      final previous = previousByMarkerId[marker.markerId];
      if (previous == null) {
        _markersToAdd.add(marker);
      } else if (marker != previous) {
        _markersToChange.add(marker);
      }
    }

    for (final markerId in previousByMarkerId.keys) {
      if (!currentByMarkerId.containsKey(markerId)) {
        _markerIdsToRemove.add(markerId);
      }
    }

    markersToAdd = Set.unmodifiable(_markersToAdd);
    markersToChange = Set.unmodifiable(_markersToChange);
    markerIdsToRemove = Set.unmodifiable(_markerIdsToRemove);
  }

  late final Set<Marker> markersToAdd;
  late final Set<Marker> markersToChange;
  late final Set<MarkerId> markerIdsToRemove;

  Map<String, dynamic> toJson() => {
        'markersToAdd': markersToAdd.map((m) => m.toJson()).toList(),
        'markersToChange': markersToChange.map((m) => m.toJson()).toList(),
        'markerIdsToRemove':
            markerIdsToRemove.map((id) => id.value).toList(),
      };
}
