import Flutter
import AMapSearchKit

class SearchChannelHandler: NSObject, FlutterPlugin, AMapSearchDelegate {

    private var searchAPI: AMapSearchAPI?
    // Keyed by the ObjectIdentifier of each AMapSearch request object so
    // multiple in-flight searches don't overwrite each other's result callback.
    private var pendingResults: [ObjectIdentifier: FlutterResult] = [:]

    override init() {
        super.init()
        searchAPI = AMapSearchAPI()
        searchAPI?.delegate = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {}

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "search#keyword":
            handleKeywordSearch(args, result: result)
        case "search#nearby":
            handleNearbySearch(args, result: result)
        case "search#regeocode":
            handleRegeocode(args, result: result)
        case "search#geocode":
            handleGeocode(args, result: result)
        case "route#driving":
            handleDrivingRoute(args, result: result)
        case "route#walking":
            handleWalkingRoute(args, result: result)
        case "search#district":
            handleDistrictSearch(args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Search Handlers

    private func handleKeywordSearch(_ args: [String: Any], result: @escaping FlutterResult) {
        let request = AMapPOIKeywordsSearchRequest()
        request.keywords = args["keyword"] as? String ?? ""
        request.city = args["city"] as? String ?? ""
        request.types = args["types"] as? String
        request.offset = args["pageSize"] as? Int ?? 20
        request.page = args["page"] as? Int ?? 1
        pendingResults[ObjectIdentifier(request)] = result
        searchAPI?.aMapPOIKeywordsSearch(request)
    }

    private func handleNearbySearch(_ args: [String: Any], result: @escaping FlutterResult) {
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(args["latitude"] as? Double ?? 0),
            longitude: CGFloat(args["longitude"] as? Double ?? 0)
        )
        request.radius = args["radius"] as? Int ?? 1000
        request.keywords = args["keyword"] as? String
        request.types = args["types"] as? String
        request.offset = args["pageSize"] as? Int ?? 20
        request.page = args["page"] as? Int ?? 1
        pendingResults[ObjectIdentifier(request)] = result
        searchAPI?.aMapPOIAroundSearch(request)
    }

    private func handleRegeocode(_ args: [String: Any], result: @escaping FlutterResult) {
        let request = AMapReGeocodeSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(args["latitude"] as? Double ?? 0),
            longitude: CGFloat(args["longitude"] as? Double ?? 0)
        )
        request.radius = 200
        request.requireExtension = true
        pendingResults[ObjectIdentifier(request)] = result
        searchAPI?.aMapReGoecodeSearch(request)
    }

    private func handleGeocode(_ args: [String: Any], result: @escaping FlutterResult) {
        let request = AMapGeocodeSearchRequest()
        request.address = args["address"] as? String ?? ""
        request.city = args["city"] as? String
        pendingResults[ObjectIdentifier(request)] = result
        searchAPI?.aMapGeocodeSearch(request)
    }

    private func handleDrivingRoute(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let originMap = args["origin"] as? [String: Any],
              let destMap = args["destination"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "origin/destination required", details: nil))
            return
        }
        let request = AMapDrivingCalRouteSearchRequest()
        request.origin = AMapGeoPoint.location(
            withLatitude: CGFloat(originMap["latitude"] as? Double ?? 0),
            longitude: CGFloat(originMap["longitude"] as? Double ?? 0)
        )
        request.destination = AMapGeoPoint.location(
            withLatitude: CGFloat(destMap["latitude"] as? Double ?? 0),
            longitude: CGFloat(destMap["longitude"] as? Double ?? 0)
        )
        if let waypointsArr = args["waypoints"] as? [[String: Any]], !waypointsArr.isEmpty {
            request.waypoints = waypointsArr.map { wp in
                AMapGeoPoint.location(
                    withLatitude: CGFloat(wp["latitude"] as? Double ?? 0),
                    longitude: CGFloat(wp["longitude"] as? Double ?? 0)
                )
            }
        }
        pendingResults[ObjectIdentifier(request)] = result
        searchAPI?.aMapDrivingV2RouteSearch(request)
    }

    private func handleWalkingRoute(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let originMap = args["origin"] as? [String: Any],
              let destMap = args["destination"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "origin/destination required", details: nil))
            return
        }
        let request = AMapWalkingRouteSearchRequest()
        request.origin = AMapGeoPoint.location(
            withLatitude: CGFloat(originMap["latitude"] as? Double ?? 0),
            longitude: CGFloat(originMap["longitude"] as? Double ?? 0)
        )
        request.destination = AMapGeoPoint.location(
            withLatitude: CGFloat(destMap["latitude"] as? Double ?? 0),
            longitude: CGFloat(destMap["longitude"] as? Double ?? 0)
        )
        pendingResults[ObjectIdentifier(request)] = result
        searchAPI?.aMapWalkingRouteSearch(request)
    }

    private func handleDistrictSearch(_ args: [String: Any], result: @escaping FlutterResult) {
        let request = AMapDistrictSearchRequest()
        request.keywords = args["keywords"] as? String ?? ""
        request.subdistrict = args["level"] as? Int ?? 3
        pendingResults[ObjectIdentifier(request)] = result
        searchAPI?.aMapDistrictSearch(request)
    }

    // MARK: - AMapSearchDelegate

    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let result = pendingResults.removeValue(forKey: ObjectIdentifier(request)) else { return }

        guard response != nil else {
            result(FlutterError(code: "SEARCH_ERROR", message: "POI search failed", details: nil))
            return
        }

        let pois = response.pois?.map { poi -> [String: Any?] in
            return [
                "poiId": poi.uid,
                "title": poi.name,
                "typeDes": poi.type,
                "typeCode": poi.typecode,
                "latitude": poi.location.map { Double($0.latitude) },
                "longitude": poi.location.map { Double($0.longitude) },
                "address": poi.address,
                "tel": poi.tel,
                "distance": poi.distance,
                "cityName": poi.city,
                "adName": poi.district,
                "snippet": poi.address,
            ]
        } ?? []

        let pageSize = request.offset > 0 ? Int(request.offset) : 20
        let pageNum = request.page > 0 ? Int(request.page) : 1
        result([
            "pois": pois,
            "totalCount": response.count,
            "pageCount": response.count > 0 ? (Int(response.count) + pageSize - 1) / pageSize : 0,
            "pageNum": pageNum,
        ] as [String: Any])
    }

    func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        guard let result = pendingResults.removeValue(forKey: ObjectIdentifier(request)) else { return }

        guard let address = response?.regeocode?.formattedAddress else {
            result(FlutterError(code: "REGEOCODE_ERROR", message: "Regeocode failed", details: nil))
            return
        }

        let addressComponent = response?.regeocode?.addressComponent
        result([
            "formattedAddress": address,
            "country": addressComponent?.country,
            "province": addressComponent?.province,
            "city": addressComponent?.city,
            "cityCode": addressComponent?.citycode,
            "district": addressComponent?.district,
            "adCode": addressComponent?.adcode,
            "street": addressComponent?.streetNumber?.street,
            "streetNumber": addressComponent?.streetNumber?.number,
            "township": addressComponent?.township,
            "townCode": addressComponent?.towncode,
        ] as [String: Any?])
    }

    func onGeocodeSearchDone(_ request: AMapGeocodeSearchRequest!, response: AMapGeocodeSearchResponse!) {
        guard let result = pendingResults.removeValue(forKey: ObjectIdentifier(request)) else { return }

        let geocodes = response?.geocodes?.map { gc -> [String: Any?] in
            return [
                "formattedAddress": gc.formattedAddress,
                "country": gc.country,
                "province": gc.province,
                "city": gc.city,
                "cityCode": gc.citycode,
                "district": gc.district,
                "adCode": gc.adcode,
                "latitude": gc.location.map { Double($0.latitude) },
                "longitude": gc.location.map { Double($0.longitude) },
                "level": gc.level,
            ]
        } ?? []
        result(geocodes)
    }

    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
        guard let result = pendingResults.removeValue(forKey: ObjectIdentifier(request)) else { return }

        guard response != nil else {
            result(FlutterError(code: "ROUTE_ERROR", message: "Route search failed", details: nil))
            return
        }

        let paths = response.route?.paths?.map { path -> [String: Any] in
            return [
                "distance": Int(path.distance),
                "duration": Int(path.duration),
                "strategy": path.strategy ?? "",
                "tolls": Double(path.tolls),
                "tollDistance": Int(path.tollDistance),
                "trafficLights": Int(path.totalTrafficLights),
                "steps": path.steps?.map { step -> [String: Any?] in
                    return [
                        "instruction": step.instruction,
                        "road": step.road,
                        "distance": Int(step.distance),
                        "duration": Int(step.duration),
                        "action": step.action,
                        "path": parsePolyline(step.polyline),
                    ]
                } ?? [],
            ]
        } ?? []
        result(["paths": paths])
    }

    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        guard let req = request as? AnyObject,
              let result = pendingResults.removeValue(forKey: ObjectIdentifier(req)) else { return }
        let nsError = error as NSError
        result(FlutterError(
            code: "SEARCH_ERROR_\(nsError.code)",
            message: nsError.localizedDescription,
            details: nil
        ))
    }

    func onDistrictSearchDone(_ request: AMapDistrictSearchRequest!, response: AMapDistrictSearchResponse!) {
        guard let result = pendingResults.removeValue(forKey: ObjectIdentifier(request)) else { return }

        func convertDistrict(_ d: AMapDistrict) -> [String: Any?] {
            return [
                "name": d.name,
                "adCode": d.adcode,
                "cityCode": d.citycode,
                "level": d.level,
                "latitude": d.center.map { Double($0.latitude) },
                "longitude": d.center.map { Double($0.longitude) },
                "districts": d.districts?.map { convertDistrict($0) } ?? [],
            ]
        }

        let items = response.districts?.map { convertDistrict($0) } ?? []
        result(items)
    }

    // MARK: - Private Helpers

    /// Parses an AMap polyline string ("lon,lat;lon,lat;...") into coordinate dictionaries.
    private func parsePolyline(_ polyline: String?) -> [[String: Double]] {
        guard let polyline = polyline, !polyline.isEmpty else { return [] }
        return polyline.split(separator: ";").compactMap { seg -> [String: Double]? in
            let parts = seg.split(separator: ",")
            guard parts.count >= 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return ["latitude": lat, "longitude": lon]
        }
    }
}
