import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'autonavi_controller.dart';
import 'types/camera_position.dart';
import 'types/circle.dart';
import 'types/latlng.dart';
import 'types/map_type.dart';
import 'types/marker.dart';
import 'types/polygon.dart';
import 'types/polyline.dart';
import 'utils/circle_updates.dart';
import 'utils/marker_updates.dart';
import 'utils/polygon_updates.dart';
import 'utils/polyline_updates.dart';

/// Callback for when the map is ready.
typedef MapCreatedCallback = void Function(AutonaviController controller);

/// Callback for camera position changes.
typedef CameraPositionCallback = void Function(CameraPosition position);

/// Preference for minimum and maximum zoom levels.
class MinMaxZoomPreference {
  const MinMaxZoomPreference(this.minZoom, this.maxZoom);

  static const MinMaxZoomPreference unbounded =
      MinMaxZoomPreference(null, null);

  final double? minZoom;
  final double? maxZoom;

  Map<String, dynamic> toJson() => {
        if (minZoom != null) 'minZoom': minZoom,
        if (maxZoom != null) 'maxZoom': maxZoom,
      };
}

/// A widget that displays an AutoNavi map.
///
/// Example usage:
/// ```dart
/// AutonaviWidget(
///   initialCameraPosition: CameraPosition(
///     target: LatLng(39.909187, 116.397451),
///     zoom: 12,
///   ),
///   onMapCreated: (controller) {
///     _controller = controller;
///   },
/// )
/// ```
class AutonaviWidget extends StatefulWidget {
  const AutonaviWidget({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
    this.mapType = MapType.normal,
    this.myLocationEnabled = false,
    this.compassEnabled = true,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.zoomControlsEnabled = true,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.gestureRecognizers = const {},
  });

  /// The initial camera position.
  final CameraPosition initialCameraPosition;

  /// Callback invoked when the map is ready to be used.
  final MapCreatedCallback? onMapCreated;

  /// Callback invoked while the camera is moving.
  final CameraPositionCallback? onCameraMove;

  /// Callback invoked when the camera movement has ended.
  final VoidCallback? onCameraIdle;

  /// Callback invoked when the user taps the map.
  final ArgumentCallback<LatLng>? onTap;

  /// Callback invoked when the user long-presses the map.
  final ArgumentCallback<LatLng>? onLongPress;

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;
  final MapType mapType;
  final bool myLocationEnabled;
  final bool compassEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool zoomControlsEnabled;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool zoomGesturesEnabled;
  final MinMaxZoomPreference minMaxZoomPreference;

  /// Gestures consumed by the map view. If empty, the map will not receive
  /// pointer events.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  State<AutonaviWidget> createState() => _AutonaviWidgetState();
}

typedef ArgumentCallback<T> = void Function(T argument);

class _AutonaviWidgetState extends State<AutonaviWidget> {
  late MethodChannel _methodChannel;
  AutonaviController? _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final creationParams = _buildCreationParams();

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'plugins.autonavi.flutter/amap_map',
        gestureRecognizers: widget.gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'plugins.autonavi.flutter/amap_map',
        gestureRecognizers: widget.gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return const Center(
      child: Text('AutoNavi Maps is not supported on this platform.'),
    );
  }

  @override
  void didUpdateWidget(AutonaviWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null) return;
    _updateMapOptions(oldWidget);
    _updateOverlays(oldWidget);
  }

  void _onPlatformViewCreated(int id) {
    _methodChannel = MethodChannel('plugins.autonavi.flutter/amap_map_$id');
    _methodChannel.setMethodCallHandler(_handleMethodCall);

    final controller = AutonaviController.init(id);
    _controller = controller;
    widget.onMapCreated?.call(controller);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'camera#onMove':
        final position = CameraPosition.fromJson(
          call.arguments as Map<dynamic, dynamic>,
        );
        widget.onCameraMove?.call(position);
      case 'camera#onIdle':
        widget.onCameraIdle?.call();
      case 'map#onTap':
        final latLng = LatLng.fromJson(call.arguments as Map<dynamic, dynamic>);
        widget.onTap?.call(latLng);
      case 'map#onLongPress':
        final latLng = LatLng.fromJson(call.arguments as Map<dynamic, dynamic>);
        widget.onLongPress?.call(latLng);
      case 'marker#onTap':
        final markerId = MarkerId(call.arguments['markerId'] as String);
        _onMarkerTap(markerId);
    }
  }

  void _onMarkerTap(MarkerId markerId) {
    final marker =
        widget.markers.where((m) => m.markerId == markerId).firstOrNull;
    marker?.onTap?.call();
  }

  Map<String, dynamic> _buildCreationParams() => {
        'initialCameraPosition': widget.initialCameraPosition.toJson(),
        'options': _buildOptions(),
        'markersToAdd': widget.markers.map((m) => m.toJson()).toList(),
        'polylinesToAdd': widget.polylines.map((p) => p.toJson()).toList(),
        'polygonsToAdd': widget.polygons.map((p) => p.toJson()).toList(),
        'circlesToAdd': widget.circles.map((c) => c.toJson()).toList(),
      };

  Map<String, dynamic> _buildOptions() => {
        'mapType': widget.mapType.index,
        'compassEnabled': widget.compassEnabled,
        'trafficEnabled': widget.trafficEnabled,
        'buildingsEnabled': widget.buildingsEnabled,
        'myLocationEnabled': widget.myLocationEnabled,
        'zoomControlsEnabled': widget.zoomControlsEnabled,
        'rotateGesturesEnabled': widget.rotateGesturesEnabled,
        'scrollGesturesEnabled': widget.scrollGesturesEnabled,
        'tiltGesturesEnabled': widget.tiltGesturesEnabled,
        'zoomGesturesEnabled': widget.zoomGesturesEnabled,
        'minMaxZoomPreference': widget.minMaxZoomPreference.toJson(),
      };

  void _updateMapOptions(AutonaviWidget oldWidget) {
    final oldOptions = _buildOptionsFrom(oldWidget);
    final newOptions = _buildOptions();
    if (oldOptions == newOptions) return;
    _methodChannel.invokeMethod('map#update', {'options': newOptions});
  }

  Map<String, dynamic> _buildOptionsFrom(AutonaviWidget w) => {
        'mapType': w.mapType.index,
        'compassEnabled': w.compassEnabled,
        'trafficEnabled': w.trafficEnabled,
        'buildingsEnabled': w.buildingsEnabled,
        'myLocationEnabled': w.myLocationEnabled,
        'zoomControlsEnabled': w.zoomControlsEnabled,
        'rotateGesturesEnabled': w.rotateGesturesEnabled,
        'scrollGesturesEnabled': w.scrollGesturesEnabled,
        'tiltGesturesEnabled': w.tiltGesturesEnabled,
        'zoomGesturesEnabled': w.zoomGesturesEnabled,
        'minMaxZoomPreference': w.minMaxZoomPreference.toJson(),
      };

  void _updateOverlays(AutonaviWidget oldWidget) {
    final markerUpdates = MarkerUpdates.from(oldWidget.markers, widget.markers);
    if (markerUpdates.markersToAdd.isNotEmpty ||
        markerUpdates.markersToChange.isNotEmpty ||
        markerUpdates.markerIdsToRemove.isNotEmpty) {
      _methodChannel.invokeMethod('markers#update', markerUpdates.toJson());
    }

    final polylineUpdates =
        PolylineUpdates.from(oldWidget.polylines, widget.polylines);
    if (polylineUpdates.polylinesToAdd.isNotEmpty ||
        polylineUpdates.polylinesToChange.isNotEmpty ||
        polylineUpdates.polylineIdsToRemove.isNotEmpty) {
      _methodChannel.invokeMethod('polylines#update', polylineUpdates.toJson());
    }

    final polygonUpdates =
        PolygonUpdates.from(oldWidget.polygons, widget.polygons);
    if (polygonUpdates.polygonsToAdd.isNotEmpty ||
        polygonUpdates.polygonsToChange.isNotEmpty ||
        polygonUpdates.polygonIdsToRemove.isNotEmpty) {
      _methodChannel.invokeMethod('polygons#update', polygonUpdates.toJson());
    }

    final circleUpdates = CircleUpdates.from(oldWidget.circles, widget.circles);
    if (circleUpdates.circlesToAdd.isNotEmpty ||
        circleUpdates.circlesToChange.isNotEmpty ||
        circleUpdates.circleIdsToRemove.isNotEmpty) {
      _methodChannel.invokeMethod('circles#update', circleUpdates.toJson());
    }
  }
}
