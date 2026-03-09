/// Accuracy level for location requests.
enum LocationAccuracy {
  /// Low accuracy, lowest battery consumption.
  low,

  /// Balanced accuracy and battery usage.
  balanced,

  /// High accuracy (GPS preferred).
  high,

  /// Best available accuracy (highest battery usage).
  best,
}

/// Options for configuring location updates.
class LocationOptions {
  const LocationOptions({
    this.accuracy = LocationAccuracy.high,
    this.intervalMs = 2000,
    this.distanceFilter = 0,
    this.needAddress = true,
    this.onceLocation = false,
  });

  /// Accuracy level for location updates.
  final LocationAccuracy accuracy;

  /// Minimum interval between location updates in milliseconds.
  final int intervalMs;

  /// Minimum distance in meters before a location update is triggered.
  final double distanceFilter;

  /// Whether to include reverse geocoding (address info) in results.
  /// This is an AutoNavi-specific feature.
  final bool needAddress;

  /// If true, performs a single location fix instead of continuous updates.
  final bool onceLocation;

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy.index,
        'intervalMs': intervalMs,
        'distanceFilter': distanceFilter,
        'needAddress': needAddress,
        'onceLocation': onceLocation,
      };
}
