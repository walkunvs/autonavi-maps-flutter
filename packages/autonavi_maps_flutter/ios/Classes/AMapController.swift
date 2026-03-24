import Flutter

class AMapController: NSObject, FlutterPlatformView {

    private let adapter: AMapSDKAdapter
    private let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        params: [String: Any]
    ) {
        adapter = AMapSDKAdapter(frame: frame)
        channel = FlutterMethodChannel(
            name: "plugins.autonavi.flutter/amap_map_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        // Wire adapter event callbacks → Flutter channel
        adapter.onCameraMove   = { [weak self] args in self?.channel.invokeMethod("camera#onMove", arguments: args) }
        adapter.onCameraIdle   = { [weak self] in self?.channel.invokeMethod("camera#onIdle", arguments: nil) }
        adapter.onMapTap       = { [weak self] args in self?.channel.invokeMethod("map#onTap", arguments: args) }
        adapter.onMapLongPress = { [weak self] args in self?.channel.invokeMethod("map#onLongPress", arguments: args) }
        adapter.onMarkerTap    = { [weak self] id in self?.channel.invokeMethod("marker#onTap", arguments: ["markerId": id]) }

        // Initial state
        if let cameraJson = params["initialCameraPosition"] as? [AnyHashable: Any] {
            adapter.applyInitialCamera(cameraJson)
        }
        if let options = params["options"] as? [String: Any] {
            adapter.applyOptions(options)
        }
        if let markersToAdd = params["markersToAdd"] as? [[AnyHashable: Any]] {
            markersToAdd.forEach { adapter.addMarker($0) }
        }
        if let polylinesToAdd = params["polylinesToAdd"] as? [[AnyHashable: Any]] {
            adapter.handlePolylineUpdates(["polylinesToAdd": polylinesToAdd])
        }
        if let polygonsToAdd = params["polygonsToAdd"] as? [[AnyHashable: Any]] {
            adapter.handlePolygonUpdates(["polygonsToAdd": polygonsToAdd])
        }
        if let circlesToAdd = params["circlesToAdd"] as? [[AnyHashable: Any]] {
            adapter.handleCircleUpdates(["circlesToAdd": circlesToAdd])
        }

        channel.setMethodCallHandler(onMethodCall)
    }

    func view() -> UIView { adapter.nativeView() }

    // MARK: - Method channel

    private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments

        switch call.method {
        case "map#update":
            if let options = (args as? [String: Any])?["options"] as? [String: Any] {
                adapter.applyOptions(options)
            }
            result(nil)

        case "map#moveCamera":
            if let json = args as? [AnyHashable: Any] { adapter.applyCameraUpdate(json, animated: false) }
            result(nil)

        case "map#animateCamera":
            if let json = args as? [AnyHashable: Any] { adapter.applyCameraUpdate(json, animated: true) }
            result(nil)

        case "map#getCameraPosition":
            result(adapter.currentCameraPosition())

        case "map#getLatLng":
            if let json = args as? [String: Any],
               let x = json["x"] as? Int, let y = json["y"] as? Int {
                result(adapter.latLng(fromScreen: x, y: y))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }

        case "map#getScreenCoordinate":
            if let json = args as? [AnyHashable: Any] {
                result(adapter.screenCoordinate(forLatLng: json))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }

        case "map#takeSnapshot":
            result(adapter.takeSnapshot())

        case "markers#update":
            if let json = args as? [AnyHashable: Any] { adapter.handleMarkerUpdates(json) }
            result(nil)

        case "markers#showInfoWindow":
            if let id = (args as? [String: Any])?["markerId"] as? String { adapter.showInfoWindow(markerId: id) }
            result(nil)

        case "markers#hideInfoWindow":
            if let id = (args as? [String: Any])?["markerId"] as? String { adapter.hideInfoWindow(markerId: id) }
            result(nil)

        case "markers#isInfoWindowShown":
            let id = (args as? [String: Any])?["markerId"] as? String ?? ""
            result(adapter.isInfoWindowShown(markerId: id))

        case "polylines#update":
            if let json = args as? [AnyHashable: Any] { adapter.handlePolylineUpdates(json) }
            result(nil)

        case "polygons#update":
            if let json = args as? [AnyHashable: Any] { adapter.handlePolygonUpdates(json) }
            result(nil)

        case "circles#update":
            if let json = args as? [AnyHashable: Any] { adapter.handleCircleUpdates(json) }
            result(nil)

        case "coordinate#convertFromWGS84":
            if let json = args as? [AnyHashable: Any] {
                result(adapter.convertFromWGS84(json))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
