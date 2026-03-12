/// A single step in a route.
class RouteStep {
  const RouteStep({
    this.instruction,
    this.road,
    this.distance,
    this.duration,
    this.action,
    this.path = const [],
  });

  final String? instruction;
  final String? road;

  /// Distance in meters.
  final double? distance;

  /// Duration in seconds.
  final double? duration;
  final String? action;

  /// List of coordinates as [lat, lng] pairs.
  final List<List<double>> path;

  factory RouteStep.fromMap(Map<dynamic, dynamic> map) => RouteStep(
        instruction: map['instruction'] as String?,
        road: map['road'] as String?,
        distance: (map['distance'] as num?)?.toDouble(),
        duration: (map['duration'] as num?)?.toDouble(),
        action: map['action'] as String?,
        path: (map['path'] as List? ?? [])
            .map((p) => [
                  (p['latitude'] as num).toDouble(),
                  (p['longitude'] as num).toDouble(),
                ])
            .toList(),
      );
}

/// A single route path returned from route planning.
class RoutePath {
  const RoutePath({
    required this.distance,
    required this.duration,
    this.steps = const [],
    this.strategy,
    this.tolls,
    this.tollDistance,
    this.trafficLights,
  });

  /// Total distance in meters.
  final double distance;

  /// Total duration in seconds.
  final double duration;
  final List<RouteStep> steps;
  final String? strategy;
  final double? tolls;
  final double? tollDistance;
  final int? trafficLights;

  factory RoutePath.fromMap(Map<dynamic, dynamic> map) => RoutePath(
        distance: (map['distance'] as num).toDouble(),
        duration: (map['duration'] as num).toDouble(),
        steps: (map['steps'] as List? ?? [])
            .map((s) => RouteStep.fromMap(s as Map))
            .toList(),
        strategy: map['strategy'] as String?,
        tolls: (map['tolls'] as num?)?.toDouble(),
        tollDistance: (map['tollDistance'] as num?)?.toDouble(),
        trafficLights: (map['trafficLights'] as num?)?.toInt(),
      );
}

/// The result of a driving route planning query.
class DrivingRouteResult {
  const DrivingRouteResult({this.paths = const []});

  final List<RoutePath> paths;

  factory DrivingRouteResult.fromMap(Map<dynamic, dynamic> map) =>
      DrivingRouteResult(
        paths: (map['paths'] as List? ?? [])
            .map((p) => RoutePath.fromMap(p as Map))
            .toList(),
      );
}

/// The result of a walking route planning query.
class WalkingRouteResult {
  const WalkingRouteResult({this.paths = const []});

  final List<RoutePath> paths;

  factory WalkingRouteResult.fromMap(Map<dynamic, dynamic> map) =>
      WalkingRouteResult(
        paths: (map['paths'] as List? ?? [])
            .map((p) => RoutePath.fromMap(p as Map))
            .toList(),
      );
}
