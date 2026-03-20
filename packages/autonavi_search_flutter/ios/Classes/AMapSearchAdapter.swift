import AMapSearchKit

/// Adapter that isolates all AMapSearchKit calls.
/// When upgrading the AMap Search SDK, only this file needs changes.
class AMapSearchAdapter: NSObject, AMapSearchDelegate {

    // MARK: - Types (no SDK types exposed)

    struct POIItem {
        let poiId: String?; let title: String?; let typeDes: String?; let typeCode: String?
        let latitude: Double?; let longitude: Double?; let address: String?; let tel: String?
        let distance: Int; let cityName: String?; let adName: String?
    }

    struct POIPage {
        let pois: [POIItem]; let totalCount: Int; let pageCount: Int; let pageNum: Int
    }

    struct AddressComponent {
        let formattedAddress: String?; let country: String?; let province: String?
        let city: String?; let cityCode: String?; let district: String?; let adCode: String?
        let street: String?; let streetNumber: String?; let township: String?; let townCode: String?
    }

    struct GeocodeItem {
        let formattedAddress: String?; let country: String?; let province: String?
        let city: String?; let cityCode: String?; let district: String?; let adCode: String?
        let latitude: Double?; let longitude: Double?; let level: String?
    }

    struct RoutePath {
        let distance: Int; let duration: Int; let strategy: String
        let tolls: Double; let tollDistance: Int; let trafficLights: Int
        let steps: [RouteStep]
    }

    struct RouteStep {
        let instruction: String?; let road: String?; let distance: Int; let duration: Int
        let action: String?; let path: [[String: Double]]
    }

    struct DistrictItem {
        let name: String?; let adCode: String?; let cityCode: String?; let level: String?
        let latitude: Double?; let longitude: Double?; let districts: [DistrictItem]
    }

    typealias POICallback       = (POIPage?, (code: String, message: String)?) -> Void
    typealias RegeocodeCallback = (AddressComponent?, (code: String, message: String)?) -> Void
    typealias GeocodeCallback   = ([GeocodeItem]?, (code: String, message: String)?) -> Void
    typealias RouteCallback     = ([RoutePath]?, (code: String, message: String)?) -> Void
    typealias DistrictCallback  = ([DistrictItem]?, (code: String, message: String)?) -> Void

    // MARK: - Private

    private var searchAPI: AMapSearchAPI?
    private var pendingPOI:      [ObjectIdentifier: (request: AMapPOISearchBaseRequest, callback: POICallback)] = [:]
    private var pendingRegeo:    [ObjectIdentifier: RegeocodeCallback] = [:]
    private var pendingGeo:      [ObjectIdentifier: GeocodeCallback] = [:]
    private var pendingRoute:    [ObjectIdentifier: RouteCallback] = [:]
    private var pendingDistrict: [ObjectIdentifier: DistrictCallback] = [:]

    override init() {
        super.init()
        searchAPI = AMapSearchAPI()
        searchAPI?.delegate = self
    }

    // MARK: - Public API

    func searchKeyword(keyword: String, city: String, types: String?,
                       pageSize: Int, page: Int, callback: @escaping POICallback) {
        let req = AMapPOIKeywordsSearchRequest()
        req.keywords = keyword; req.city = city; req.types = types
        req.offset = pageSize; req.page = page
        pendingPOI[ObjectIdentifier(req)] = (req, callback)
        searchAPI?.aMapPOIKeywordsSearch(req)
    }

    func searchNearby(latitude: Double, longitude: Double, radius: Int,
                      keyword: String?, types: String?,
                      pageSize: Int, page: Int, callback: @escaping POICallback) {
        let req = AMapPOIAroundSearchRequest()
        req.location = AMapGeoPoint.location(withLatitude: CGFloat(latitude), longitude: CGFloat(longitude))
        req.radius = radius; req.keywords = keyword; req.types = types
        req.offset = pageSize; req.page = page
        pendingPOI[ObjectIdentifier(req)] = (req, callback)
        searchAPI?.aMapPOIAroundSearch(req)
    }

    func regeocode(latitude: Double, longitude: Double, callback: @escaping RegeocodeCallback) {
        let req = AMapReGeocodeSearchRequest()
        req.location = AMapGeoPoint.location(withLatitude: CGFloat(latitude), longitude: CGFloat(longitude))
        req.radius = 200; req.requireExtension = true
        pendingRegeo[ObjectIdentifier(req)] = callback
        searchAPI?.aMapReGoecodeSearch(req)
    }

    func geocode(address: String, city: String?, callback: @escaping GeocodeCallback) {
        let req = AMapGeocodeSearchRequest()
        req.address = address; req.city = city
        pendingGeo[ObjectIdentifier(req)] = callback
        searchAPI?.aMapGeocodeSearch(req)
    }

    func drivingRoute(originLat: Double, originLng: Double,
                      destLat: Double, destLng: Double,
                      waypoints: [(lat: Double, lng: Double)],
                      callback: @escaping RouteCallback) {
        let req = AMapDrivingCalRouteSearchRequest()
        req.origin = AMapGeoPoint.location(withLatitude: CGFloat(originLat), longitude: CGFloat(originLng))
        req.destination = AMapGeoPoint.location(withLatitude: CGFloat(destLat), longitude: CGFloat(destLng))
        if !waypoints.isEmpty {
            req.waypoints = waypoints.map {
                AMapGeoPoint.location(withLatitude: CGFloat($0.lat), longitude: CGFloat($0.lng))
            }
        }
        pendingRoute[ObjectIdentifier(req)] = callback
        searchAPI?.aMapDrivingV2RouteSearch(req)
    }

    func walkingRoute(originLat: Double, originLng: Double,
                      destLat: Double, destLng: Double,
                      callback: @escaping RouteCallback) {
        let req = AMapWalkingRouteSearchRequest()
        req.origin = AMapGeoPoint.location(withLatitude: CGFloat(originLat), longitude: CGFloat(originLng))
        req.destination = AMapGeoPoint.location(withLatitude: CGFloat(destLat), longitude: CGFloat(destLng))
        pendingRoute[ObjectIdentifier(req)] = callback
        searchAPI?.aMapWalkingRouteSearch(req)
    }

    func searchDistrict(keywords: String, level: Int, callback: @escaping DistrictCallback) {
        let req = AMapDistrictSearchRequest()
        req.keywords = keywords; req.subdistrict = level
        pendingDistrict[ObjectIdentifier(req)] = callback
        searchAPI?.aMapDistrictSearch(req)
    }

    // MARK: - AMapSearchDelegate

    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let entry = pendingPOI.removeValue(forKey: ObjectIdentifier(request)) else { return }
        let callback = entry.callback
        let req = entry.request
        guard let response = response else {
            callback(nil, (code: "SEARCH_ERROR", message: "POI search failed"))
            return
        }
        let pois = (response.pois ?? []).map { poi -> POIItem in
            POIItem(
                poiId: poi.uid, title: poi.name, typeDes: poi.type, typeCode: poi.typecode,
                latitude: poi.location.map { Double($0.latitude) },
                longitude: poi.location.map { Double($0.longitude) },
                address: poi.address, tel: poi.tel, distance: Int(poi.distance),
                cityName: poi.city, adName: poi.district
            )
        }
        let pageSize = req.offset > 0 ? Int(req.offset) : 20
        let pageNum  = req.page  > 0 ? Int(req.page)   : 1
        let total    = Int(response.count)
        let pageCount = total > 0 ? (total + pageSize - 1) / pageSize : 0
        callback(POIPage(pois: pois, totalCount: total, pageCount: pageCount, pageNum: pageNum), nil)
    }

    func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        guard let callback = pendingRegeo.removeValue(forKey: ObjectIdentifier(request)) else { return }
        guard let address = response?.regeocode?.formattedAddress else {
            callback(nil, (code: "REGEOCODE_ERROR", message: "Regeocode failed"))
            return
        }
        let ac = response?.regeocode?.addressComponent
        callback(AddressComponent(
            formattedAddress: address, country: ac?.country, province: ac?.province,
            city: ac?.city, cityCode: ac?.citycode, district: ac?.district, adCode: ac?.adcode,
            street: ac?.streetNumber?.street, streetNumber: ac?.streetNumber?.number,
            township: ac?.township, townCode: ac?.towncode
        ), nil)
    }

    func onGeocodeSearchDone(_ request: AMapGeocodeSearchRequest!, response: AMapGeocodeSearchResponse!) {
        guard let callback = pendingGeo.removeValue(forKey: ObjectIdentifier(request)) else { return }
        let items = (response?.geocodes ?? []).map { gc -> GeocodeItem in
            GeocodeItem(
                formattedAddress: gc.formattedAddress, country: gc.country, province: gc.province,
                city: gc.city, cityCode: gc.citycode, district: gc.district, adCode: gc.adcode,
                latitude: gc.location.map { Double($0.latitude) },
                longitude: gc.location.map { Double($0.longitude) },
                level: gc.level
            )
        }
        callback(items, nil)
    }

    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
        guard let callback = pendingRoute.removeValue(forKey: ObjectIdentifier(request)) else { return }
        guard let response = response else {
            callback(nil, (code: "ROUTE_ERROR", message: "Route search failed"))
            return
        }
        let paths = (response.route?.paths ?? []).map { path -> RoutePath in
            let steps = (path.steps ?? []).map { step -> RouteStep in
                RouteStep(
                    instruction: step.instruction, road: step.road,
                    distance: Int(step.distance), duration: Int(step.duration),
                    action: step.action, path: parsePolyline(step.polyline)
                )
            }
            return RoutePath(
                distance: Int(path.distance), duration: Int(path.duration),
                strategy: path.strategy ?? "", tolls: Double(path.tolls),
                tollDistance: Int(path.tollDistance), trafficLights: Int(path.totalTrafficLights),
                steps: steps
            )
        }
        callback(paths, nil)
    }

    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        guard let req = request as? AnyObject else { return }
        let key = ObjectIdentifier(req)
        let nsError = error as NSError
        let err = (code: "SEARCH_ERROR_\(nsError.code)", message: nsError.localizedDescription)

        if let entry = pendingPOI.removeValue(forKey: key)      { entry.callback(nil, err); return }
        if let cb    = pendingRegeo.removeValue(forKey: key)     { cb(nil, err); return }
        if let cb    = pendingGeo.removeValue(forKey: key)       { cb(nil, err); return }
        if let cb    = pendingRoute.removeValue(forKey: key)     { cb(nil, err); return }
        if let cb    = pendingDistrict.removeValue(forKey: key)  { cb(nil, err) }
    }

    func onDistrictSearchDone(_ request: AMapDistrictSearchRequest!, response: AMapDistrictSearchResponse!) {
        guard let callback = pendingDistrict.removeValue(forKey: ObjectIdentifier(request)) else { return }
        let items = (response?.districts ?? []).map { convertDistrict($0) }
        callback(items, nil)
    }

    // MARK: - Private helpers

    private func convertDistrict(_ d: AMapDistrict) -> DistrictItem {
        return DistrictItem(
            name: d.name, adCode: d.adcode, cityCode: d.citycode, level: d.level,
            latitude: d.center.map { Double($0.latitude) },
            longitude: d.center.map { Double($0.longitude) },
            districts: (d.districts ?? []).map { convertDistrict($0) }
        )
    }

    private func parsePolyline(_ polyline: String?) -> [[String: Double]] {
        guard let polyline = polyline, !polyline.isEmpty else { return [] }
        return polyline.split(separator: ";").compactMap { seg -> [String: Double]? in
            let parts = seg.split(separator: ",")
            guard parts.count >= 2, let lon = Double(parts[0]), let lat = Double(parts[1]) else { return nil }
            return ["latitude": lat, "longitude": lon]
        }
    }
}
