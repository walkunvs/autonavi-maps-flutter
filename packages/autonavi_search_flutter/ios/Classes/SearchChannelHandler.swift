import Flutter

class SearchChannelHandler: NSObject, FlutterPlugin {

    private let adapter = AMapSearchAdapter()

    override init() { super.init() }

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
        adapter.searchKeyword(
            keyword:  args["keyword"]  as? String ?? "",
            city:     args["city"]     as? String ?? "",
            types:    args["types"]    as? String,
            pageSize: args["pageSize"] as? Int ?? 20,
            page:     args["page"]     as? Int ?? 1
        ) { page, err in
            if let err = err { result(FlutterError(code: err.code, message: err.message, details: nil)); return }
            result(poiPageToMap(page!))
        }
    }

    private func handleNearbySearch(_ args: [String: Any], result: @escaping FlutterResult) {
        adapter.searchNearby(
            latitude:  args["latitude"]  as? Double ?? 0,
            longitude: args["longitude"] as? Double ?? 0,
            radius:    args["radius"]    as? Int ?? 1000,
            keyword:   args["keyword"]   as? String,
            types:     args["types"]     as? String,
            pageSize:  args["pageSize"]  as? Int ?? 20,
            page:      args["page"]      as? Int ?? 1
        ) { page, err in
            if let err = err { result(FlutterError(code: err.code, message: err.message, details: nil)); return }
            result(poiPageToMap(page!))
        }
    }

    private func handleRegeocode(_ args: [String: Any], result: @escaping FlutterResult) {
        adapter.regeocode(
            latitude:  args["latitude"]  as? Double ?? 0,
            longitude: args["longitude"] as? Double ?? 0
        ) { ac, err in
            if let err = err { result(FlutterError(code: err.code, message: err.message, details: nil)); return }
            guard let ac = ac else { result(nil); return }
            result([
                "formattedAddress": ac.formattedAddress, "country": ac.country,
                "province": ac.province, "city": ac.city, "cityCode": ac.cityCode,
                "district": ac.district, "adCode": ac.adCode, "street": ac.street,
                "streetNumber": ac.streetNumber, "township": ac.township, "townCode": ac.townCode,
            ] as [String: Any?])
        }
    }

    private func handleGeocode(_ args: [String: Any], result: @escaping FlutterResult) {
        adapter.geocode(
            address: args["address"] as? String ?? "",
            city:    args["city"]    as? String
        ) { items, err in
            if let err = err { result(FlutterError(code: err.code, message: err.message, details: nil)); return }
            let maps = (items ?? []).map { gc -> [String: Any?] in
                ["formattedAddress": gc.formattedAddress, "country": gc.country,
                 "province": gc.province, "city": gc.city, "cityCode": gc.cityCode,
                 "district": gc.district, "adCode": gc.adCode,
                 "latitude": gc.latitude, "longitude": gc.longitude, "level": gc.level]
            }
            result(maps)
        }
    }

    private func handleDrivingRoute(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let originMap = args["origin"] as? [String: Any],
              let destMap   = args["destination"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "origin/destination required", details: nil))
            return
        }
        let waypoints = (args["waypoints"] as? [[String: Any]] ?? []).map {
            (lat: $0["latitude"] as? Double ?? 0, lng: $0["longitude"] as? Double ?? 0)
        }
        adapter.drivingRoute(
            originLat: originMap["latitude"] as? Double ?? 0,
            originLng: originMap["longitude"] as? Double ?? 0,
            destLat:   destMap["latitude"]   as? Double ?? 0,
            destLng:   destMap["longitude"]  as? Double ?? 0,
            waypoints: waypoints
        ) { paths, err in
            if let err = err { result(FlutterError(code: err.code, message: err.message, details: nil)); return }
            result(["paths": (paths ?? []).map { routePathToMap($0) }])
        }
    }

    private func handleWalkingRoute(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let originMap = args["origin"] as? [String: Any],
              let destMap   = args["destination"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "origin/destination required", details: nil))
            return
        }
        adapter.walkingRoute(
            originLat: originMap["latitude"] as? Double ?? 0,
            originLng: originMap["longitude"] as? Double ?? 0,
            destLat:   destMap["latitude"]   as? Double ?? 0,
            destLng:   destMap["longitude"]  as? Double ?? 0
        ) { paths, err in
            if let err = err { result(FlutterError(code: err.code, message: err.message, details: nil)); return }
            result(["paths": (paths ?? []).map { routePathToMap($0) }])
        }
    }

    private func handleDistrictSearch(_ args: [String: Any], result: @escaping FlutterResult) {
        adapter.searchDistrict(
            keywords: args["keywords"] as? String ?? "",
            level:    args["level"]    as? Int ?? 3
        ) { items, err in
            if let err = err { result(FlutterError(code: err.code, message: err.message, details: nil)); return }
            result((items ?? []).map { districtToMap($0) })
        }
    }
}

// MARK: - Map conversion helpers (free functions, no SDK imports)

private func poiPageToMap(_ page: AMapSearchAdapter.POIPage) -> [String: Any] {
    return [
        "pois": page.pois.map { poi -> [String: Any?] in
            ["poiId": poi.poiId, "title": poi.title, "typeDes": poi.typeDes,
             "typeCode": poi.typeCode, "latitude": poi.latitude, "longitude": poi.longitude,
             "address": poi.address, "tel": poi.tel, "distance": poi.distance,
             "cityName": poi.cityName, "adName": poi.adName, "snippet": poi.address]
        },
        "totalCount": page.totalCount,
        "pageCount":  page.pageCount,
        "pageNum":    page.pageNum,
    ]
}

private func routePathToMap(_ path: AMapSearchAdapter.RoutePath) -> [String: Any] {
    return [
        "distance":     path.distance,
        "duration":     path.duration,
        "strategy":     path.strategy,
        "tolls":        path.tolls,
        "tollDistance": path.tollDistance,
        "trafficLights":path.trafficLights,
        "steps": path.steps.map { step -> [String: Any?] in
            ["instruction": step.instruction, "road": step.road,
             "distance": step.distance, "duration": step.duration,
             "action": step.action, "path": step.path]
        },
    ]
}

private func districtToMap(_ d: AMapSearchAdapter.DistrictItem) -> [String: Any?] {
    return [
        "name": d.name, "adCode": d.adCode, "cityCode": d.cityCode, "level": d.level,
        "latitude": d.latitude, "longitude": d.longitude,
        "districts": d.districts.map { districtToMap($0) },
    ]
}
