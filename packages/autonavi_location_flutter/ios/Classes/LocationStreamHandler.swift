import Flutter
import AMapLocationKit

class LocationStreamHandler: NSObject, FlutterStreamHandler, AMapLocationManagerDelegate {

    private var locationManager: AMapLocationManager?
    private var eventSink: FlutterEventSink?
    private var onceCallback: ((Any?) -> Void)?
    private var isOnce = false

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        let options = arguments as? [String: Any] ?? [:]
        startLocation(options: options, once: false)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopLocation()
        return nil
    }

    // MARK: - Public

    func getOnce(options: [String: Any], callback: @escaping (Any?) -> Void) {
        onceCallback = callback
        startLocation(options: options, once: true)
    }

    func updateOptions(_ options: [String: Any]) {
        guard let manager = locationManager else { return }
        applyOptions(options, to: manager)
    }

    // MARK: - AMapLocationManagerDelegate

    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!, reGeocode: AMapLocationReGeocode?) {
        let result = buildResultMap(location: location, reGeocode: reGeocode)

        if isOnce {
            let callback = onceCallback
            onceCallback = nil
            stopLocation()
            callback?(result)
        } else {
            eventSink?(result)
        }
    }

    func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
        let nsError = error as NSError
        if isOnce {
            let flutterError = FlutterError(
                code: "LOCATION_ERROR_\(nsError.code)",
                message: nsError.localizedDescription,
                details: nil
            )
            let callback = onceCallback
            onceCallback = nil
            stopLocation()
            callback?(flutterError)
        } else {
            eventSink?(FlutterError(
                code: "LOCATION_ERROR_\(nsError.code)",
                message: nsError.localizedDescription,
                details: nil
            ))
        }
    }

    // MARK: - Private

    private func startLocation(options: [String: Any], once: Bool) {
        isOnce = once
        let manager = AMapLocationManager()
        manager.delegate = self
        applyOptions(options, to: manager)
        manager.startUpdatingLocation()
        locationManager = manager
    }

    private func stopLocation() {
        locationManager?.stopUpdatingLocation()
        locationManager?.delegate = nil
        locationManager = nil
        eventSink = nil
    }

    private func applyOptions(_ options: [String: Any], to manager: AMapLocationManager) {
        let accuracyIndex = options["accuracy"] as? Int ?? 2
        switch accuracyIndex {
        case 0:
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        case 1:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        case 3:
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        default:
            manager.desiredAccuracy = kCLLocationAccuracyBest
        }

        let intervalMs = options["intervalMs"] as? Int ?? 2000
        manager.locationTimeout = max(2, intervalMs / 1000)
        manager.reGeocodeTimeout = max(2, intervalMs / 1000)

        let needAddress = options["needAddress"] as? Bool ?? true
        manager.locatingWithReGeocode = needAddress
    }

    private func buildResultMap(
        location: CLLocation,
        reGeocode: AMapLocationReGeocode?
    ) -> [String: Any?] {
        return [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "altitude": location.altitude,
            "speed": location.speed >= 0 ? location.speed : nil,
            "heading": location.course >= 0 ? location.course : nil,
            "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000),
            "address": reGeocode?.formattedAddress,
            "country": reGeocode?.country,
            "province": reGeocode?.province,
            "city": reGeocode?.city,
            "district": reGeocode?.district,
            "street": reGeocode?.street,
            "streetNum": reGeocode?.number,
            "cityCode": reGeocode?.citycode,
            "adCode": reGeocode?.adcode,
            "poiName": reGeocode?.POIName,
            "aoiName": reGeocode?.AOIName,
        ]
    }
}
