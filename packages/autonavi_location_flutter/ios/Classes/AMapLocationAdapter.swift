import AMapLocationKit

/// Options passed to the location adapter. Plain Swift struct — no SDK types exposed.
struct LocationOptions {
    var accuracy: Int
    var intervalMs: Int
    var needAddress: Bool
}

/// Result returned from a successful location update. All SDK types are hidden.
typealias LocationResult = [String: Any?]

/// Adapter that isolates all AMapLocationKit calls.
/// When upgrading the AMap Location SDK, only this file needs changes.
class AMapLocationAdapter: NSObject, AMapLocationManagerDelegate {

    // MARK: - Callbacks (set by caller, no SDK types in signatures)

    var onLocation: ((LocationResult) -> Void)?
    var onError: ((code: String, message: String) -> Void)?

    // MARK: - Private

    private var manager: AMapLocationManager?
    private var isOnce = false
    private var onceCallback: ((LocationResult?, (code: String, message: String)?) -> Void)?

    // MARK: - Public API

    func startContinuous(options: LocationOptions) {
        isOnce = false
        let m = makeManager(options: options)
        m.startUpdatingLocation()
        manager = m
    }

    func startOnce(options: LocationOptions,
                   callback: @escaping (LocationResult?, (code: String, message: String)?) -> Void) {
        isOnce = true
        onceCallback = callback
        let m = makeManager(options: options)
        m.startUpdatingLocation()
        manager = m
    }

    func stop() {
        manager?.stopUpdatingLocation()
        manager?.delegate = nil
        manager = nil
    }

    func updateOptions(_ options: LocationOptions) {
        guard let m = manager else { return }
        applyOptions(options, to: m)
    }

    // MARK: - AMapLocationManagerDelegate

    func amapLocationManager(_ manager: AMapLocationManager!,
                             didUpdate location: CLLocation!,
                             reGeocode: AMapLocationReGeocode?) {
        let result = buildResult(location: location, reGeocode: reGeocode)
        if isOnce {
            let cb = onceCallback
            onceCallback = nil
            stop()
            cb?(result, nil)
        } else {
            onLocation?(result)
        }
    }

    func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
        let nsError = error as NSError
        let err = (code: "LOCATION_ERROR_\(nsError.code)", message: nsError.localizedDescription)
        if isOnce {
            let cb = onceCallback
            onceCallback = nil
            stop()
            cb?(nil, err)
        } else {
            onError?(err)
        }
    }

    // MARK: - Private helpers

    private func makeManager(options: LocationOptions) -> AMapLocationManager {
        let m = AMapLocationManager()
        m.delegate = self
        applyOptions(options, to: m)
        return m
    }

    private func applyOptions(_ options: LocationOptions, to m: AMapLocationManager) {
        switch options.accuracy {
        case 0: m.desiredAccuracy = kCLLocationAccuracyHundredMeters
        case 1: m.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        case 3: m.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        default: m.desiredAccuracy = kCLLocationAccuracyBest
        }
        m.locationTimeout = max(2, options.intervalMs / 1000)
        m.reGeocodeTimeout = max(2, options.intervalMs / 1000)
        m.locatingWithReGeocode = options.needAddress
    }

    private func buildResult(location: CLLocation, reGeocode: AMapLocationReGeocode?) -> LocationResult {
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
            "poiName": reGeocode?.poiName,
            "aoiName": reGeocode?.aoiName,
        ]
    }
}
