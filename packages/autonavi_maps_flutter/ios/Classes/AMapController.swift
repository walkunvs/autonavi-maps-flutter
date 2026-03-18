import Flutter
import MAMapKit
import AMapFoundationKit

class AMapController: NSObject, FlutterPlatformView, MAMapViewDelegate {

    private let mapView: MAMapView
    private let channel: FlutterMethodChannel
    private var markers: [String: MAPointAnnotation] = [:]
    private var polylines: [String: MAPolyline] = [:]
    private var polygons: [String: MAPolygon] = [:]
    private var circles: [String: MACircle] = [:]
    private var markerAnnotationViews: [String: MAAnnotationView] = [:]
    private var markerIdByAnnotation: [ObjectIdentifier: String] = [:]

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        params: [String: Any]
    ) {
        mapView = MAMapView(frame: frame)
        channel = FlutterMethodChannel(
            name: "plugins.autonavi.flutter/amap_map_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()
        mapView.delegate = self

        if let cameraJson = params["initialCameraPosition"] as? [AnyHashable: Any] {
            applyInitialCamera(cameraJson)
        }

        if let options = params["options"] as? [String: Any] {
            applyMapOptions(options)
        }

        if let markersToAdd = params["markersToAdd"] as? [[AnyHashable: Any]] {
            markersToAdd.forEach { addMarker($0) }
        }

        if let polylinesToAdd = params["polylinesToAdd"] as? [[AnyHashable: Any]] {
            polylinesToAdd.forEach { addPolyline($0) }
        }

        if let polygonsToAdd = params["polygonsToAdd"] as? [[AnyHashable: Any]] {
            polygonsToAdd.forEach { addPolygon($0) }
        }

        if let circlesToAdd = params["circlesToAdd"] as? [[AnyHashable: Any]] {
            circlesToAdd.forEach { addCircle($0) }
        }

        channel.setMethodCallHandler(onMethodCall)
    }

    func view() -> UIView { mapView }

    private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments

        switch call.method {
        case "map#update":
            if let options = (args as? [String: Any])?["options"] as? [String: Any] {
                applyMapOptions(options)
            }
            result(nil)

        case "map#moveCamera":
            if let json = args as? [AnyHashable: Any] {
                applyCameraUpdate(json, animated: false)
            }
            result(nil)

        case "map#animateCamera":
            if let json = args as? [AnyHashable: Any] {
                applyCameraUpdate(json, animated: true)
            }
            result(nil)

        case "map#getCameraPosition":
            result(Convert.fromCameraPosition(mapView: mapView))

        case "map#getLatLng":
            if let json = args as? [String: Any],
               let x = json["x"] as? Int,
               let y = json["y"] as? Int {
                let point = CGPoint(x: x, y: y)
                let coord = mapView.convert(point, toCoordinateFrom: mapView)
                result(Convert.fromLatLng(coord))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }

        case "map#getScreenCoordinate":
            if let json = args as? [AnyHashable: Any] {
                let coord = Convert.toLatLng(json)
                let point = mapView.convert(coord, toPointTo: mapView)
                result(["x": Int(point.x), "y": Int(point.y)])
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }

        case "map#takeSnapshot":
            UIGraphicsBeginImageContextWithOptions(mapView.bounds.size, true, 0)
            mapView.drawHierarchy(in: mapView.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let data = image?.pngData() {
                result(FlutterStandardTypedData(bytes: data))
            } else {
                result(nil)
            }

        case "markers#update":
            if let json = args as? [AnyHashable: Any] { handleMarkerUpdates(json) }
            result(nil)

        case "markers#showInfoWindow":
            if let markerId = (args as? [String: Any])?["markerId"] as? String,
               let annotation = markers[markerId] {
                mapView.selectAnnotation(annotation, animated: true)
            }
            result(nil)

        case "markers#hideInfoWindow":
            if let markerId = (args as? [String: Any])?["markerId"] as? String,
               let annotation = markers[markerId] {
                mapView.deselectAnnotation(annotation, animated: true)
            }
            result(nil)

        case "markers#isInfoWindowShown":
            let markerId = (args as? [String: Any])?["markerId"] as? String
            let isShown = markerId.flatMap { markers[$0] }.map { annotation in
                mapView.selectedAnnotations.contains { ($0 as AnyObject) === annotation }
            } ?? false
            result(isShown)

        case "polylines#update":
            if let json = args as? [AnyHashable: Any] { handlePolylineUpdates(json) }
            result(nil)

        case "polygons#update":
            if let json = args as? [AnyHashable: Any] { handlePolygonUpdates(json) }
            result(nil)

        case "circles#update":
            if let json = args as? [AnyHashable: Any] { handleCircleUpdates(json) }
            result(nil)

        case "coordinate#convertFromWGS84":
            if let json = args as? [AnyHashable: Any] {
                let wgs84 = Convert.toLatLng(json)
                let gcj02 = AMapCoordinateConvert(wgs84, AMapCoordinateType.GPS)
                result(Convert.fromLatLng(gcj02))
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - MAMapViewDelegate

    func mapView(_ mapView: MAMapView!, regionWillChangeAnimated animated: Bool) {
        channel.invokeMethod("camera#onMove", arguments: Convert.fromCameraPosition(mapView: mapView))
    }

    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        channel.invokeMethod("camera#onIdle", arguments: nil)
    }

    func mapView(_ mapView: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) {
        channel.invokeMethod("map#onTap", arguments: Convert.fromLatLng(coordinate))
    }

    func mapView(_ mapView: MAMapView!, didLongPressedAt coordinate: CLLocationCoordinate2D) {
        channel.invokeMethod("map#onLongPress", arguments: Convert.fromLatLng(coordinate))
    }

    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
        guard let annotation = view.annotation as? MAPointAnnotation else { return }
        let markerId = markerIdByAnnotation[ObjectIdentifier(annotation)]
        if let markerId = markerId {
            channel.invokeMethod("marker#onTap", arguments: ["markerId": markerId])
        }
    }

    // MARK: - Helpers

    private func applyInitialCamera(_ json: [AnyHashable: Any]) {
        if let targetJson = json["target"] as? [AnyHashable: Any] {
            let center = Convert.toLatLng(targetJson)
            mapView.centerCoordinate = center
        }
        if let zoom = (json["zoom"] as? NSNumber)?.floatValue {
            mapView.zoomLevel = CGFloat(zoom)
        }
        if let bearing = (json["bearing"] as? NSNumber)?.floatValue {
            mapView.rotationDegree = CGFloat(bearing)
        }
        if let tilt = (json["tilt"] as? NSNumber)?.floatValue {
            mapView.cameraDegree = CGFloat(tilt)
        }
    }

    private func applyMapOptions(_ options: [String: Any]) {
        if let mapTypeIndex = options["mapType"] as? Int {
            mapView.mapType = Convert.toMapType(mapTypeIndex)
        }
        if let compass = options["compassEnabled"] as? Bool {
            mapView.showsCompass = compass
        }
        if let traffic = options["trafficEnabled"] as? Bool {
            mapView.isShowTraffic = traffic
        }
        if let buildings = options["buildingsEnabled"] as? Bool {
            mapView.isShowsBuildings = buildings
        }
        if let myLocation = options["myLocationEnabled"] as? Bool {
            mapView.showsUserLocation = myLocation
        }
        if let zoomControls = options["zoomControlsEnabled"] as? Bool {
            mapView.showsScale = zoomControls
        }
        if let rotate = options["rotateGesturesEnabled"] as? Bool {
            mapView.isRotateEnabled = rotate
        }
        if let scroll = options["scrollGesturesEnabled"] as? Bool {
            mapView.isScrollEnabled = scroll
        }
        if let tilt = options["tiltGesturesEnabled"] as? Bool {
            mapView.isRotateCameraEnabled = tilt
        }
        if let zoom = options["zoomGesturesEnabled"] as? Bool {
            mapView.isZoomEnabled = zoom
        }
        if let minMax = options["minMaxZoomPreference"] as? [String: Any] {
            if let minZoom = (minMax["minZoom"] as? NSNumber)?.floatValue {
                mapView.minZoomLevel = CGFloat(minZoom)
            }
            if let maxZoom = (minMax["maxZoom"] as? NSNumber)?.floatValue {
                mapView.maxZoomLevel = CGFloat(maxZoom)
            }
        }
    }

    private func applyCameraUpdate(_ json: [AnyHashable: Any], animated: Bool) {
        if let posJson = json["newCameraPosition"] as? [AnyHashable: Any] {
            applyInitialCamera(posJson)
            return
        }
        if let latLngJson = json["newLatLng"] as? [AnyHashable: Any] {
            let coord = Convert.toLatLng(latLngJson)
            if animated {
                mapView.setCenter(coord, animated: true)
            } else {
                mapView.centerCoordinate = coord
            }
            return
        }
        if let lzJson = json["newLatLngZoom"] as? [AnyHashable: Any],
           let latLngJson = lzJson["latLng"] as? [AnyHashable: Any],
           let zoom = lzJson["zoom"] as? NSNumber {
            let coord = Convert.toLatLng(latLngJson)
            mapView.centerCoordinate = coord
            mapView.setZoomLevel(CGFloat(zoom.floatValue), animated: animated)
            return
        }
        if let zoom = json["zoomTo"] as? NSNumber {
            mapView.setZoomLevel(CGFloat(zoom.floatValue), animated: animated)
            return
        }
        if json["zoomIn"] != nil {
            mapView.setZoomLevel(mapView.zoomLevel + 1, animated: animated)
            return
        }
        if json["zoomOut"] != nil {
            mapView.setZoomLevel(mapView.zoomLevel - 1, animated: animated)
            return
        }
        if let amount = json["zoomBy"] as? NSNumber {
            mapView.setZoomLevel(mapView.zoomLevel + CGFloat(amount.floatValue), animated: animated)
            return
        }
    }

    private func addMarker(_ json: [AnyHashable: Any]) {
        guard let markerId = json["markerId"] as? String,
              let posJson = json["position"] as? [AnyHashable: Any] else { return }
        let annotation = MAPointAnnotation()
        annotation.coordinate = Convert.toLatLng(posJson)
        if let infoWindow = json["infoWindow"] as? [AnyHashable: Any] {
            annotation.title = infoWindow["title"] as? String
            annotation.subtitle = infoWindow["snippet"] as? String
        }
        mapView.addAnnotation(annotation)
        markers[markerId] = annotation
        markerIdByAnnotation[ObjectIdentifier(annotation)] = markerId
    }

    private func handleMarkerUpdates(_ json: [AnyHashable: Any]) {
        if let toAdd = json["markersToAdd"] as? [[AnyHashable: Any]] {
            toAdd.forEach { addMarker($0) }
        }
        if let toChange = json["markersToChange"] as? [[AnyHashable: Any]] {
            toChange.forEach { markerJson in
                guard let markerId = markerJson["markerId"] as? String else { return }
                if let existing = markers[markerId] {
                    markerIdByAnnotation.removeValue(forKey: ObjectIdentifier(existing))
                    mapView.removeAnnotation(existing)
                }
                addMarker(markerJson)
            }
        }
        if let toRemove = json["markerIdsToRemove"] as? [String] {
            toRemove.forEach { id in
                if let annotation = markers.removeValue(forKey: id) {
                    markerIdByAnnotation.removeValue(forKey: ObjectIdentifier(annotation))
                    mapView.removeAnnotation(annotation)
                }
            }
        }
    }

    private func addPolyline(_ json: [AnyHashable: Any]) {
        guard let polylineId = json["polylineId"] as? String,
              let pointsJson = json["points"] as? [[AnyHashable: Any]] else { return }
        var coords = pointsJson.map { Convert.toLatLng($0) }
        let polyline = MAPolyline(coordinates: &coords, count: UInt(coords.count))
        mapView.add(polyline)
        polylines[polylineId] = polyline
    }

    private func handlePolylineUpdates(_ json: [AnyHashable: Any]) {
        if let toAdd = json["polylinesToAdd"] as? [[AnyHashable: Any]] {
            toAdd.forEach { addPolyline($0) }
        }
        if let toChange = json["polylinesToChange"] as? [[AnyHashable: Any]] {
            toChange.forEach { pJson in
                guard let id = pJson["polylineId"] as? String else { return }
                if let existing = polylines.removeValue(forKey: id) {
                    mapView.remove(existing)
                }
                addPolyline(pJson)
            }
        }
        if let toRemove = json["polylineIdsToRemove"] as? [String] {
            toRemove.forEach { id in
                if let overlay = polylines.removeValue(forKey: id) {
                    mapView.remove(overlay)
                }
            }
        }
    }

    private func addPolygon(_ json: [AnyHashable: Any]) {
        guard let polygonId = json["polygonId"] as? String,
              let pointsJson = json["points"] as? [[AnyHashable: Any]] else { return }
        var coords = pointsJson.map { Convert.toLatLng($0) }
        let polygon = MAPolygon(coordinates: &coords, count: UInt(coords.count))
        mapView.add(polygon)
        polygons[polygonId] = polygon
    }

    private func handlePolygonUpdates(_ json: [AnyHashable: Any]) {
        if let toAdd = json["polygonsToAdd"] as? [[AnyHashable: Any]] {
            toAdd.forEach { addPolygon($0) }
        }
        if let toChange = json["polygonsToChange"] as? [[AnyHashable: Any]] {
            toChange.forEach { pJson in
                guard let id = pJson["polygonId"] as? String else { return }
                if let existing = polygons.removeValue(forKey: id) {
                    mapView.remove(existing)
                }
                addPolygon(pJson)
            }
        }
        if let toRemove = json["polygonIdsToRemove"] as? [String] {
            toRemove.forEach { id in
                if let overlay = polygons.removeValue(forKey: id) {
                    mapView.remove(overlay)
                }
            }
        }
    }

    private func addCircle(_ json: [AnyHashable: Any]) {
        guard let circleId = json["circleId"] as? String,
              let centerJson = json["center"] as? [AnyHashable: Any],
              let radius = (json["radius"] as? NSNumber)?.doubleValue else { return }
        let center = Convert.toLatLng(centerJson)
        let circle = MACircle(center: center, radius: radius)
        mapView.add(circle)
        circles[circleId] = circle
    }

    private func handleCircleUpdates(_ json: [AnyHashable: Any]) {
        if let toAdd = json["circlesToAdd"] as? [[AnyHashable: Any]] {
            toAdd.forEach { addCircle($0) }
        }
        if let toChange = json["circlesToChange"] as? [[AnyHashable: Any]] {
            toChange.forEach { cJson in
                guard let id = cJson["circleId"] as? String else { return }
                if let existing = circles.removeValue(forKey: id) {
                    mapView.remove(existing)
                }
                addCircle(cJson)
            }
        }
        if let toRemove = json["circleIdsToRemove"] as? [String] {
            toRemove.forEach { id in
                if let overlay = circles.removeValue(forKey: id) {
                    mapView.remove(overlay)
                }
            }
        }
    }
}
