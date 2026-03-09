import MAMapKit
import UIKit

struct Convert {

    static func toLatLng(_ json: [AnyHashable: Any]) -> CLLocationCoordinate2D {
        let lat = (json["latitude"] as! NSNumber).doubleValue
        let lng = (json["longitude"] as! NSNumber).doubleValue
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    static func fromLatLng(_ coordinate: CLLocationCoordinate2D) -> [String: Double] {
        return ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
    }

    static func toCameraPosition(_ json: [AnyHashable: Any]) -> MACoordinateRegion? {
        guard let targetJson = json["target"] as? [AnyHashable: Any] else { return nil }
        let center = toLatLng(targetJson)
        // Return a region with a default span; the mapView will apply zoom separately
        return MACoordinateRegion(center: center, span: MACoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    }

    static func fromCameraPosition(mapView: MAMapView) -> [String: Any] {
        return [
            "target": fromLatLng(mapView.centerCoordinate),
            "zoom": Double(mapView.zoomLevel),
            "bearing": Double(mapView.rotationDegree),
            "tilt": Double(mapView.cameraDegree),
        ]
    }

    static func toMapType(_ index: Int) -> MAMapType {
        switch index {
        case 1: return .satellite
        case 2: return .standardNight
        case 3: return .navi
        case 4: return .bus
        default: return .standard
        }
    }

    static func toUIColor(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
