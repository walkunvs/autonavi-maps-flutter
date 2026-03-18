import MAMapKit
import AMapFoundationKit

/// Adapter that isolates all MAMapKit / AMapFoundationKit calls for the map view.
/// When upgrading the AMap 3D Map SDK, only this file needs changes.
class AMapSDKAdapter: NSObject, MAMapViewDelegate {

    // MARK: - Event callbacks (no SDK types in signatures)

    var onCameraMove:   (([String: Any]) -> Void)?
    var onCameraIdle:   (() -> Void)?
    var onMapTap:       (([String: Any]) -> Void)?
    var onMapLongPress: (([String: Any]) -> Void)?
    var onMarkerTap:    ((String) -> Void)?   // markerId

    // MARK: - Private SDK objects

    private let mapView: MAMapView
    private var markers:   [String: MAPointAnnotation] = [:]
    private var polylines: [String: MAPolyline] = [:]
    private var polygons:  [String: MAPolygon] = [:]
    private var circles:   [String: MACircle] = [:]
    private var markerIdByAnnotation: [ObjectIdentifier: String] = [:]

    // MARK: - Init

    init(frame: CGRect) {
        mapView = MAMapView(frame: frame)
        super.init()
        mapView.delegate = self
    }

    // MARK: - Native view

    func nativeView() -> UIView { mapView }

    // MARK: - Camera

    func applyInitialCamera(_ json: [AnyHashable: Any]) {
        if let targetJson = json["target"] as? [AnyHashable: Any] {
            mapView.centerCoordinate = Convert.toLatLng(targetJson)
        }
        if let zoom    = (json["zoom"]    as? NSNumber)?.floatValue { mapView.zoomLevel    = CGFloat(zoom) }
        if let bearing = (json["bearing"] as? NSNumber)?.floatValue { mapView.rotationDegree = CGFloat(bearing) }
        if let tilt    = (json["tilt"]    as? NSNumber)?.floatValue { mapView.cameraDegree  = CGFloat(tilt) }
    }

    func applyCameraUpdate(_ json: [AnyHashable: Any], animated: Bool) {
        if let posJson = json["newCameraPosition"] as? [AnyHashable: Any] {
            applyInitialCamera(posJson); return
        }
        if let latLngJson = json["newLatLng"] as? [AnyHashable: Any] {
            let coord = Convert.toLatLng(latLngJson)
            if animated { mapView.setCenter(coord, animated: true) } else { mapView.centerCoordinate = coord }
            return
        }
        if let lzJson = json["newLatLngZoom"] as? [AnyHashable: Any],
           let latLngJson = lzJson["latLng"] as? [AnyHashable: Any],
           let zoom = lzJson["zoom"] as? NSNumber {
            mapView.centerCoordinate = Convert.toLatLng(latLngJson)
            mapView.setZoomLevel(CGFloat(zoom.floatValue), animated: animated); return
        }
        if let zoom = json["zoomTo"]  as? NSNumber { mapView.setZoomLevel(CGFloat(zoom.floatValue), animated: animated); return }
        if json["zoomIn"]  != nil { mapView.setZoomLevel(mapView.zoomLevel + 1, animated: animated); return }
        if json["zoomOut"] != nil { mapView.setZoomLevel(mapView.zoomLevel - 1, animated: animated); return }
        if let amount = json["zoomBy"] as? NSNumber { mapView.setZoomLevel(mapView.zoomLevel + CGFloat(amount.floatValue), animated: animated) }
    }

    func currentCameraPosition() -> [String: Any] {
        return Convert.fromCameraPosition(mapView: mapView)
    }

    // MARK: - Projection

    func latLng(fromScreen x: Int, y: Int) -> [String: Any] {
        return Convert.fromLatLng(mapView.convert(CGPoint(x: x, y: y), toCoordinateFrom: mapView))
    }

    func screenCoordinate(forLatLng json: [AnyHashable: Any]) -> [String: Int] {
        let point = mapView.convert(Convert.toLatLng(json), toPointTo: mapView)
        return ["x": Int(point.x), "y": Int(point.y)]
    }

    // MARK: - Snapshot

    func takeSnapshot() -> FlutterStandardTypedData? {
        UIGraphicsBeginImageContextWithOptions(mapView.bounds.size, true, 0)
        mapView.drawHierarchy(in: mapView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.pngData().map { FlutterStandardTypedData(bytes: $0) }
    }

    // MARK: - Map options

    func applyOptions(_ options: [String: Any]) {
        if let v = options["mapType"]          as? Int  { mapView.mapType = Convert.toMapType(v) }
        if let v = options["compassEnabled"]   as? Bool { mapView.showsCompass = v }
        if let v = options["trafficEnabled"]   as? Bool { mapView.isShowTraffic = v }
        if let v = options["buildingsEnabled"] as? Bool { mapView.isShowsBuildings = v }
        if let v = options["myLocationEnabled"]     as? Bool { mapView.showsUserLocation = v }
        if let v = options["zoomControlsEnabled"]   as? Bool { mapView.showsScale = v }
        if let v = options["rotateGesturesEnabled"]  as? Bool { mapView.isRotateEnabled = v }
        if let v = options["scrollGesturesEnabled"]  as? Bool { mapView.isScrollEnabled = v }
        if let v = options["tiltGesturesEnabled"]    as? Bool { mapView.isRotateCameraEnabled = v }
        if let v = options["zoomGesturesEnabled"]    as? Bool { mapView.isZoomEnabled = v }
        if let minMax = options["minMaxZoomPreference"] as? [String: Any] {
            if let min = (minMax["minZoom"] as? NSNumber)?.floatValue { mapView.minZoomLevel = CGFloat(min) }
            if let max = (minMax["maxZoom"] as? NSNumber)?.floatValue { mapView.maxZoomLevel = CGFloat(max) }
        }
    }

    // MARK: - Overlays

    func addMarker(_ json: [AnyHashable: Any]) {
        guard let markerId = json["markerId"] as? String,
              let posJson  = json["position"] as? [AnyHashable: Any] else { return }
        let annotation = MAPointAnnotation()
        annotation.coordinate = Convert.toLatLng(posJson)
        if let iw = json["infoWindow"] as? [AnyHashable: Any] {
            annotation.title    = iw["title"]   as? String
            annotation.subtitle = iw["snippet"] as? String
        }
        mapView.addAnnotation(annotation)
        markers[markerId] = annotation
        markerIdByAnnotation[ObjectIdentifier(annotation)] = markerId
    }

    func handleMarkerUpdates(_ json: [AnyHashable: Any]) {
        (json["markersToAdd"]    as? [[AnyHashable: Any]])?.forEach { addMarker($0) }
        (json["markersToChange"] as? [[AnyHashable: Any]])?.forEach { j in
            guard let id = j["markerId"] as? String else { return }
            if let existing = markers[id] {
                markerIdByAnnotation.removeValue(forKey: ObjectIdentifier(existing))
                mapView.removeAnnotation(existing)
            }
            addMarker(j)
        }
        (json["markerIdsToRemove"] as? [String])?.forEach { id in
            if let a = markers.removeValue(forKey: id) {
                markerIdByAnnotation.removeValue(forKey: ObjectIdentifier(a))
                mapView.removeAnnotation(a)
            }
        }
    }

    func showInfoWindow(markerId: String)   { if let a = markers[markerId] { mapView.selectAnnotation(a, animated: true) } }
    func hideInfoWindow(markerId: String)   { if let a = markers[markerId] { mapView.deselectAnnotation(a, animated: true) } }
    func isInfoWindowShown(markerId: String) -> Bool {
        guard let a = markers[markerId] else { return false }
        return mapView.selectedAnnotations.contains { ($0 as AnyObject) === a }
    }

    func handlePolylineUpdates(_ json: [AnyHashable: Any]) {
        (json["polylinesToAdd"]    as? [[AnyHashable: Any]])?.forEach { addPolyline($0) }
        (json["polylinesToChange"] as? [[AnyHashable: Any]])?.forEach { j in
            if let id = j["polylineId"] as? String, let ol = polylines.removeValue(forKey: id) { mapView.remove(ol) }
            addPolyline(j)
        }
        (json["polylineIdsToRemove"] as? [String])?.forEach { id in
            if let ol = polylines.removeValue(forKey: id) { mapView.remove(ol) }
        }
    }

    func handlePolygonUpdates(_ json: [AnyHashable: Any]) {
        (json["polygonsToAdd"]    as? [[AnyHashable: Any]])?.forEach { addPolygon($0) }
        (json["polygonsToChange"] as? [[AnyHashable: Any]])?.forEach { j in
            if let id = j["polygonId"] as? String, let ol = polygons.removeValue(forKey: id) { mapView.remove(ol) }
            addPolygon(j)
        }
        (json["polygonIdsToRemove"] as? [String])?.forEach { id in
            if let ol = polygons.removeValue(forKey: id) { mapView.remove(ol) }
        }
    }

    func handleCircleUpdates(_ json: [AnyHashable: Any]) {
        (json["circlesToAdd"]    as? [[AnyHashable: Any]])?.forEach { addCircle($0) }
        (json["circlesToChange"] as? [[AnyHashable: Any]])?.forEach { j in
            if let id = j["circleId"] as? String, let ol = circles.removeValue(forKey: id) { mapView.remove(ol) }
            addCircle(j)
        }
        (json["circleIdsToRemove"] as? [String])?.forEach { id in
            if let ol = circles.removeValue(forKey: id) { mapView.remove(ol) }
        }
    }

    // MARK: - Coordinate conversion

    func convertFromWGS84(_ json: [AnyHashable: Any]) -> [String: Any] {
        let gcj02 = AMapCoordinateConvert(Convert.toLatLng(json), AMapCoordinateType.GPS)
        return Convert.fromLatLng(gcj02)
    }

    // MARK: - MAMapViewDelegate

    func mapView(_ mapView: MAMapView!, regionWillChangeAnimated animated: Bool) {
        onCameraMove?(Convert.fromCameraPosition(mapView: mapView))
    }

    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        onCameraIdle?()
    }

    func mapView(_ mapView: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) {
        onMapTap?(Convert.fromLatLng(coordinate))
    }

    func mapView(_ mapView: MAMapView!, didLongPressedAt coordinate: CLLocationCoordinate2D) {
        onMapLongPress?(Convert.fromLatLng(coordinate))
    }

    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
        guard let annotation = view.annotation as? MAPointAnnotation,
              let markerId = markerIdByAnnotation[ObjectIdentifier(annotation)] else { return }
        onMarkerTap?(markerId)
    }

    // MARK: - Private overlay helpers

    private func addPolyline(_ json: [AnyHashable: Any]) {
        guard let id = json["polylineId"] as? String,
              let pts = json["points"] as? [[AnyHashable: Any]] else { return }
        var coords = pts.map { Convert.toLatLng($0) }
        let ol = MAPolyline(coordinates: &coords, count: UInt(coords.count))
        mapView.add(ol)
        polylines[id] = ol
    }

    private func addPolygon(_ json: [AnyHashable: Any]) {
        guard let id = json["polygonId"] as? String,
              let pts = json["points"] as? [[AnyHashable: Any]] else { return }
        var coords = pts.map { Convert.toLatLng($0) }
        let ol = MAPolygon(coordinates: &coords, count: UInt(coords.count))
        mapView.add(ol)
        polygons[id] = ol
    }

    private func addCircle(_ json: [AnyHashable: Any]) {
        guard let id = json["circleId"] as? String,
              let centerJson = json["center"] as? [AnyHashable: Any],
              let radius = (json["radius"] as? NSNumber)?.doubleValue else { return }
        let ol = MACircle(center: Convert.toLatLng(centerJson), radius: radius)
        mapView.add(ol)
        circles[id] = ol
    }
}
