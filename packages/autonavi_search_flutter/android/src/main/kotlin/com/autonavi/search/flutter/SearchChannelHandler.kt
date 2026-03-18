package com.autonavi.search.flutter

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SearchChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val adapter = AMapSearchAdapter(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: emptyMap()

        when (call.method) {
            "search#keyword"  -> searchKeyword(args, result)
            "search#nearby"   -> searchNearby(args, result)
            "search#regeocode"-> regeocode(args, result)
            "search#geocode"  -> geocode(args, result)
            "route#driving"   -> drivingRoute(args, result)
            "route#walking"   -> walkingRoute(args, result)
            "search#district" -> searchDistrict(args, result)
            else -> result.notImplemented()
        }
    }

    private fun searchKeyword(args: Map<String, Any>, result: MethodChannel.Result) {
        adapter.searchKeyword(
            keyword  = args["keyword"]  as String,
            city     = args["city"]     as String,
            types    = args["types"]    as? String ?: "",
            page     = (args["page"]     as? Int) ?: 1,
            pageSize = (args["pageSize"] as? Int) ?: 20,
        ) { page, err ->
            if (err != null) { result.error(err.first, err.second, null); return@searchKeyword }
            result.success(poiPageToMap(page!!))
        }
    }

    private fun searchNearby(args: Map<String, Any>, result: MethodChannel.Result) {
        adapter.searchNearby(
            lat      = (args["latitude"]  as Number).toDouble(),
            lng      = (args["longitude"] as Number).toDouble(),
            radius   = (args["radius"]    as? Int) ?: 1000,
            keyword  = args["keyword"]    as? String ?: "",
            types    = args["types"]      as? String ?: "",
            page     = (args["page"]      as? Int) ?: 1,
            pageSize = (args["pageSize"]  as? Int) ?: 20,
        ) { page, err ->
            if (err != null) { result.error(err.first, err.second, null); return@searchNearby }
            result.success(poiPageToMap(page!!))
        }
    }

    private fun regeocode(args: Map<String, Any>, result: MethodChannel.Result) {
        adapter.regeocode(
            lat = (args["latitude"]  as Number).toDouble(),
            lng = (args["longitude"] as Number).toDouble(),
        ) { ac, err ->
            if (err != null) { result.error(err.first, err.second, null); return@regeocode }
            result.success(ac?.let {
                mapOf(
                    "formattedAddress" to it.formattedAddress,
                    "country"   to it.country,   "province"  to it.province,
                    "city"      to it.city,       "cityCode"  to it.cityCode,
                    "district"  to it.district,   "adCode"    to it.adCode,
                    "street"    to it.street,      "streetNumber" to it.streetNumber,
                    "township"  to it.township,   "townCode"  to it.townCode,
                )
            })
        }
    }

    private fun geocode(args: Map<String, Any>, result: MethodChannel.Result) {
        adapter.geocode(
            address = args["address"] as String,
            city    = args["city"]    as? String ?: "",
        ) { items, err ->
            if (err != null) { result.error(err.first, err.second, null); return@geocode }
            result.success((items ?: emptyList()).map { gc ->
                mapOf(
                    "formattedAddress" to gc.formattedAddress,
                    "country"   to gc.country,  "province" to gc.province,
                    "city"      to gc.city,      "district" to gc.district,
                    "adCode"    to gc.adCode,
                    "latitude"  to gc.latitude,  "longitude" to gc.longitude,
                    "level"     to gc.level,
                )
            })
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun drivingRoute(args: Map<String, Any>, result: MethodChannel.Result) {
        val originMap = args["origin"]      as Map<String, Any>
        val destMap   = args["destination"] as Map<String, Any>
        val waypoints = (args["waypoints"] as? List<Map<String, Any>>)?.map {
            (it["latitude"] as Number).toDouble() to (it["longitude"] as Number).toDouble()
        } ?: emptyList()

        adapter.drivingRoute(
            originLat = (originMap["latitude"]  as Number).toDouble(),
            originLng = (originMap["longitude"] as Number).toDouble(),
            destLat   = (destMap["latitude"]    as Number).toDouble(),
            destLng   = (destMap["longitude"]   as Number).toDouble(),
            waypoints = waypoints,
        ) { paths, err ->
            if (err != null) { result.error(err.first, err.second, null); return@drivingRoute }
            result.success(mapOf("paths" to (paths ?: emptyList()).map { routePathToMap(it) }))
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun walkingRoute(args: Map<String, Any>, result: MethodChannel.Result) {
        val originMap = args["origin"]      as Map<String, Any>
        val destMap   = args["destination"] as Map<String, Any>

        adapter.walkingRoute(
            originLat = (originMap["latitude"]  as Number).toDouble(),
            originLng = (originMap["longitude"] as Number).toDouble(),
            destLat   = (destMap["latitude"]    as Number).toDouble(),
            destLng   = (destMap["longitude"]   as Number).toDouble(),
        ) { paths, err ->
            if (err != null) { result.error(err.first, err.second, null); return@walkingRoute }
            result.success(mapOf("paths" to (paths ?: emptyList()).map { routePathToMap(it) }))
        }
    }

    private fun searchDistrict(args: Map<String, Any>, result: MethodChannel.Result) {
        adapter.searchDistrict(keywords = args["keywords"] as String) { items, err ->
            if (err != null) { result.error(err.first, err.second, null); return@searchDistrict }
            result.success((items ?: emptyList()).map { districtToMap(it) })
        }
    }

    // MARK: - Map conversion helpers (no SDK types)

    private fun poiPageToMap(page: AMapSearchAdapter.POIPage): Map<String, Any> = mapOf(
        "pois" to page.pois.map { poi ->
            mapOf(
                "poiId"    to poi.poiId,    "title"   to poi.title,
                "typeDes"  to poi.typeDes,  "typeCode" to poi.typeCode,
                "latitude" to poi.latitude, "longitude" to poi.longitude,
                "address"  to poi.address,  "tel"     to poi.tel,
                "distance" to poi.distance, "cityName" to poi.cityName,
                "adName"   to poi.adName,   "snippet"  to poi.address,
            )
        },
        "totalCount" to page.totalCount,
        "pageCount"  to page.pageCount,
        "pageNum"    to page.pageNum,
    )

    private fun routePathToMap(path: AMapSearchAdapter.RoutePath): Map<String, Any?> = mapOf(
        "distance"     to path.distance,
        "duration"     to path.duration,
        "strategy"     to path.strategy,
        "tolls"        to path.tolls,
        "tollDistance" to path.tollDistance,
        "trafficLights" to path.trafficLights,
        "steps" to path.steps.map { step ->
            mapOf(
                "instruction" to step.instruction, "road"     to step.road,
                "distance"    to step.distance,    "duration" to step.duration,
                "action"      to step.action,       "path"    to step.path,
            )
        },
    )

    private fun districtToMap(d: AMapSearchAdapter.DistrictNode): Map<String, Any?> = mapOf(
        "name"      to d.name,     "adCode"   to d.adCode,
        "cityCode"  to d.cityCode, "level"    to d.level,
        "latitude"  to d.latitude, "longitude" to d.longitude,
        "districts" to d.districts.map { districtToMap(it) },
    )
}
