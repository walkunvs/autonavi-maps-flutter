import Flutter
import AMapSearchKit

class SearchChannelHandler: NSObject, FlutterPlugin, AMapSearchDelegate {

    private var searchAPI: AMapSearchAPI?
    private var pendingResult: FlutterResult?
    private var pendingMethod: String?

    override init() {
        super.init()
        searchAPI = AMapSearchAPI()
        searchAPI?.delegate = self
    }

    public static func register(with registrar: FlutterPluginRegistrar) {}

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        pendingResult = result
        pendingMethod = call.method

        switch call.method {
        case "search#keyword":
            handleKeywordSearch(args)
        case "search#nearby":
            handleNearbySearch(args)
        case "search#regeocode":
            handleRegeocode(args)
        case "search#geocode":
            handleGeocode(args)
        case "route#driving":
            handleDrivingRoute(args)
        case "route#walking":
            handleWalkingRoute(args)
        case "search#district":
            handleDistrictSearch(args)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Search Handlers

    private func handleKeywordSearch(_ args: [String: Any]) {
        let request = AMapPOIKeywordsSearchRequest()
        request.keywords = args["keyword"] as? String ?? ""
        request.city = args["city"] as? String ?? ""
        request.types = args["types"] as? String
        request.offset = Int32(args["pageSize"] as? Int ?? 20)
        request.page = Int32(args["page"] as? Int ?? 1)
        request.requireExtension = true
        searchAPI?.aMapPOIKeywordsSearch(request)
    }

    private func handleNearbySearch(_ args: [String: Any]) {
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(args["latitude"] as? Double ?? 0),
            longitude: CGFloat(args["longitude"] as? Double ?? 0)
        )
        request.radius = Int32(args["radius"] as? Int ?? 1000)
        request.keywords = args["keyword"] as? String
        request.types = args["types"] as? String
        request.offset = Int32(args["pageSize"] as? Int ?? 20)
        request.page = Int32(args["page"] as? Int ?? 1)
        request.requireExtension = true
        searchAPI?.aMapPOIAroundSearch(request)
    }

    private func handleRegeocode(_ args: [String: Any]) {
        let request = AMapReGeocodeSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(args["latitude"] as? Double ?? 0),
            longitude: CGFloat(args["longitude"] as? Double ?? 0)
        )
        request.radius = 200
        request.requireExtension = true
        searchAPI?.aMapReGoecodeSearch(request)
    }

    private func handleGeocode(_ args: [String: Any]) {
        let request = AMapGeocodeSearchRequest()
        request.address = args["address"] as? String ?? ""
        request.city = args["city"] as? String
        searchAPI?.aMapGoecodeSearch(request)
    }

    private func handleDrivingRoute(_ args: [String: Any]) {
        guard let originMap = args["origin"] as? [String: Any],
              let destMap = args["destination"] as? [String: Any] else { return }
        let request = AMapDrivingRouteSearchRequest()
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
        searchAPI?.aMapDrivingRouteSearch(request)
    }

    private func handleWalkingRoute(_ args: [String: Any]) {
        guard let originMap = args["origin"] as? [String: Any],
              let destMap = args["destination"] as? [String: Any] else { return }
        let request = AMapWalkingRouteSearchRequest()
        request.origin = AMapGeoPoint.location(
            withLatitude: CGFloat(originMap["latitude"] as? Double ?? 0),
            longitude: CGFloat(originMap["longitude"] as? Double ?? 0)
        )
        request.destination = AMapGeoPoint.location(
            withLatitude: CGFloat(destMap["latitude"] as? Double ?? 0),
            longitude: CGFloat(destMap["longitude"] as? Double ?? 0)
        )
        searchAPI?.aMapWalkingRouteSearch(request)
    }

    private func handleDistrictSearch(_ args: [String: Any]) {
        let request = AMapDistrictSearchRequest()
        request.keywords = args["keywords"] as? String ?? ""
        request.level = UInt32(args["level"] as? Int ?? 3)
        request.showBoundary = false
        searchAPI?.aMapDistrictSearch(request)
    }

    // MARK: - AMapSearchDelegate

    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let result = pendingResult else { return }
        pendingResult = nil

        guard response != nil else {
            result(FlutterError(code: "SEARCH_ERROR", message: "POI search failed", details: nil))
            return
        }

        let pois = response.pois?.map { poi -> [String: Any?] in
            return [
                "poiId": poi.uid,
                "title": poi.name,
                "typeDes": poi.type,
                "typeCode": poi.typeCode,
                "latitude": poi.location?.latitude.map { Double($0) },
                "longitude": poi.location?.longitude.map { Double($0) },
                "address": poi.address,
                "tel": poi.tel,
                "distance": poi.distance,
                "cityName": poi.city,
                "adName": poi.adname,
                "snippet": poi.address,
            ]
        } ?? []

        result([
            "pois": pois,
            "totalCount": response.count,
            "pageCount": (response.count + 19) / 20,
            "pageNum": 1,
        ] as [String: Any])
    }

    func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        guard let result = pendingResult else { return }
        pendingResult = nil

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
        guard let result = pendingResult else { return }
        pendingResult = nil

        let geocodes = response?.geocodes?.map { gc -> [String: Any?] in
            return [
                "formattedAddress": gc.formattedAddress,
                "country": gc.country,
                "province": gc.province,
                "city": gc.city,
                "cityCode": gc.citycode,
                "district": gc.district,
                "adCode": gc.adcode,
                "latitude": gc.location?.latitude.map { Double($0) },
                "longitude": gc.location?.longitude.map { Double($0) },
                "level": gc.level,
            ]
        } ?? []
        result(geocodes)
    }

    func onRouteSearchDone(_ request: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
        guard let result = pendingResult else { return }
        pendingResult = nil

        if let drivingResp = response as? AMapDrivingRouteSearchResponse ?? nil {
            let paths = drivingResp.route?.paths?.map { path -> [String: Any] in
                return [
                    "distance": Double(path.distance),
                    "duration": Double(path.duration),
                    "strategy": path.strategy ?? "",
                    "tolls": Double(path.tolls),
                    "tollDistance": Double(path.tollDistance),
                    "trafficLights": Int(path.trafficLights),
                    "steps": path.steps?.map { step -> [String: Any?] in
                        return [
                            "instruction": step.instruction,
                            "road": step.road,
                            "distance": Double(step.distance),
                            "duration": Double(step.duration),
                            "action": step.action,
                            "path": step.polyline?.map { pt -> [String: Double] in
                                return ["latitude": Double(pt.latitude), "longitude": Double(pt.longitude)]
                            } ?? [],
                        ]
                    } ?? [],
                ]
            } ?? []
            result(["paths": paths])
        } else if let walkingResp = response as? AMapWalkingRouteSearchResponse ?? nil {
            let paths = walkingResp.route?.paths?.map { path -> [String: Any] in
                return [
                    "distance": Double(path.distance),
                    "duration": Double(path.duration),
                    "steps": path.steps?.map { step -> [String: Any?] in
                        return [
                            "instruction": step.instruction,
                            "road": step.road,
                            "distance": Double(step.distance),
                            "duration": Double(step.duration),
                            "action": step.action,
                            "path": step.polyline?.map { pt -> [String: Double] in
                                return ["latitude": Double(pt.latitude), "longitude": Double(pt.longitude)]
                            } ?? [],
                        ]
                    } ?? [],
                ]
            } ?? []
            result(["paths": paths])
        } else {
            result(FlutterError(code: "ROUTE_ERROR", message: "Route search failed", details: nil))
        }
    }

    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        guard let result = pendingResult else { return }
        pendingResult = nil
        let nsError = error as NSError
        result(FlutterError(
            code: "SEARCH_ERROR_\(nsError.code)",
            message: nsError.localizedDescription,
            details: nil
        ))
    }

    func onDistrictSearchDone(_ request: AMapDistrictSearchRequest!, response: AMapDistrictSearchResponse!) {
        guard let result = pendingResult else { return }
        pendingResult = nil

        func convertDistrict(_ d: AMapDistrict) -> [String: Any?] {
            let centerParts = d.center?.split(separator: ",")
            return [
                "name": d.name,
                "adCode": d.adcode,
                "cityCode": d.citycode,
                "level": d.level,
                "latitude": centerParts?.count == 2 ? Double(centerParts![1]) : nil,
                "longitude": centerParts?.count == 2 ? Double(centerParts![0]) : nil,
                "districts": d.districts?.map { convertDistrict($0) } ?? [],
            ]
        }

        let items = response.districts?.map { convertDistrict($0) } ?? []
        result(items)
    }
}
