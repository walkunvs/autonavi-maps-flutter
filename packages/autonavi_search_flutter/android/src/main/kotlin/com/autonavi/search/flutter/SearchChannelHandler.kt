package com.autonavi.search.flutter

import android.content.Context
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.geocoder.GeocodeAddress
import com.amap.api.services.geocoder.GeocodeQuery
import com.amap.api.services.geocoder.GeocodeResult
import com.amap.api.services.geocoder.GeocodeSearch
import com.amap.api.services.geocoder.RegeocodeQuery
import com.amap.api.services.geocoder.RegeocodeResult
import com.amap.api.services.district.DistrictItem
import com.amap.api.services.district.DistrictResult
import com.amap.api.services.district.DistrictSearch
import com.amap.api.services.district.DistrictSearchQuery
import com.amap.api.services.core.PoiItem
import com.amap.api.services.poisearch.PoiResult
import com.amap.api.services.poisearch.PoiSearch
import com.amap.api.services.route.DrivePath
import com.amap.api.services.route.DriveRouteResult
import com.amap.api.services.route.RouteSearch
import com.amap.api.services.route.WalkPath
import com.amap.api.services.route.WalkRouteResult
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SearchChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "search#keyword" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                searchKeyword(args, result)
            }
            "search#nearby" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                searchNearby(args, result)
            }
            "search#regeocode" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                regeocode(args, result)
            }
            "search#geocode" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                geocode(args, result)
            }
            "route#driving" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                drivingRoute(args, result)
            }
            "route#walking" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                walkingRoute(args, result)
            }
            "search#district" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                searchDistrict(args, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun searchKeyword(args: Map<String, Any>, result: MethodChannel.Result) {
        val keyword = args["keyword"] as String
        val city = args["city"] as String
        val types = args["types"] as? String ?: ""
        val page = (args["page"] as? Int) ?: 1
        val pageSize = (args["pageSize"] as? Int) ?: 20

        val query = PoiSearch.Query(keyword, types, city)
        query.pageNum = page - 1
        query.pageSize = pageSize
        val search = PoiSearch(context, query)
        search.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
            override fun onPoiSearched(poiResult: PoiResult?, resultCode: Int) {
                if (resultCode == 1000 && poiResult != null) {
                    result.success(poiResultToMap(poiResult, page))
                } else {
                    result.error("SEARCH_ERROR_$resultCode", "POI search failed", null)
                }
            }
            override fun onPoiItemSearched(item: PoiItem?, resultCode: Int) {}
        })
        search.searchPOIAsyn()
    }

    private fun searchNearby(args: Map<String, Any>, result: MethodChannel.Result) {
        val lat = (args["latitude"] as Number).toDouble()
        val lng = (args["longitude"] as Number).toDouble()
        val radius = (args["radius"] as? Int) ?: 1000
        val keyword = args["keyword"] as? String ?: ""
        val types = args["types"] as? String ?: ""
        val page = (args["page"] as? Int) ?: 1
        val pageSize = (args["pageSize"] as? Int) ?: 20

        val query = PoiSearch.Query(keyword, types, "")
        query.pageNum = page - 1
        query.pageSize = pageSize
        val search = PoiSearch(context, query)
        search.bound = PoiSearch.SearchBound(LatLonPoint(lat, lng), radius)
        search.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
            override fun onPoiSearched(poiResult: PoiResult?, resultCode: Int) {
                if (resultCode == 1000 && poiResult != null) {
                    result.success(poiResultToMap(poiResult, page))
                } else {
                    result.error("SEARCH_ERROR_$resultCode", "Nearby search failed", null)
                }
            }
            override fun onPoiItemSearched(item: PoiItem?, resultCode: Int) {}
        })
        search.searchPOIAsyn()
    }

    private fun regeocode(args: Map<String, Any>, result: MethodChannel.Result) {
        val lat = (args["latitude"] as Number).toDouble()
        val lng = (args["longitude"] as Number).toDouble()
        val search = GeocodeSearch(context)
        val query = RegeocodeQuery(LatLonPoint(lat, lng), 200f, GeocodeSearch.AMAP)
        search.setOnGeocodeSearchListener(object : GeocodeSearch.OnGeocodeSearchListener {
            override fun onRegeocodeSearched(geocodeResult: RegeocodeResult?, resultCode: Int) {
                if (resultCode == 1000 && geocodeResult != null) {
                    val address = geocodeResult.regeocodeAddress
                    result.success(mapOf(
                        "formattedAddress" to address.formatAddress,
                        "country" to address.country,
                        "province" to address.province,
                        "city" to address.city,
                        "cityCode" to address.cityCode,
                        "district" to address.district,
                        "adCode" to address.adCode,
                        "street" to address.streetNumber?.street,
                        "streetNumber" to address.streetNumber?.number,
                        "township" to address.township,
                        "townCode" to address.towncode,
                    ))
                } else {
                    result.error("REGEOCODE_ERROR_$resultCode", "Regeocode failed", null)
                }
            }
            override fun onGeocodeSearched(geocodeResult: GeocodeResult?, resultCode: Int) {}
        })
        search.getFromLocationAsyn(query)
    }

    private fun geocode(args: Map<String, Any>, result: MethodChannel.Result) {
        val address = args["address"] as String
        val city = args["city"] as? String ?: ""
        val search = GeocodeSearch(context)
        val query = GeocodeQuery(address, city)
        search.setOnGeocodeSearchListener(object : GeocodeSearch.OnGeocodeSearchListener {
            override fun onRegeocodeSearched(geocodeResult: RegeocodeResult?, resultCode: Int) {}
            override fun onGeocodeSearched(geocodeResult: GeocodeResult?, resultCode: Int) {
                if (resultCode == 1000 && geocodeResult != null) {
                    val items = geocodeResult.geocodeAddressList?.map { addr: GeocodeAddress ->
                        mapOf(
                            "formattedAddress" to addr.formatAddress,
                            "country" to addr.country,
                            "province" to addr.province,
                            "city" to addr.city,
                            "district" to addr.district,
                            "adCode" to addr.adcode,
                            "latitude" to addr.latLonPoint?.latitude,
                            "longitude" to addr.latLonPoint?.longitude,
                            "level" to addr.level,
                        )
                    } ?: emptyList<Map<String, Any?>>()
                    result.success(items)
                } else {
                    result.error("GEOCODE_ERROR_$resultCode", "Geocode failed", null)
                }
            }
        })
        search.getFromLocationNameAsyn(query)
    }

    private fun drivingRoute(args: Map<String, Any>, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val originMap = args["origin"] as Map<String, Any>
        @Suppress("UNCHECKED_CAST")
        val destMap = args["destination"] as Map<String, Any>
        val origin = LatLonPoint(
            (originMap["latitude"] as Number).toDouble(),
            (originMap["longitude"] as Number).toDouble()
        )
        val dest = LatLonPoint(
            (destMap["latitude"] as Number).toDouble(),
            (destMap["longitude"] as Number).toDouble()
        )

        val search = RouteSearch(context)
        val fromAndTo = RouteSearch.FromAndTo(origin, dest)
        val query = RouteSearch.DriveRouteQuery(fromAndTo, RouteSearch.DrivingDefault, null, null, "")
        search.setRouteSearchListener(object : RouteSearch.OnRouteSearchListener {
            override fun onDriveRouteSearched(routeResult: DriveRouteResult?, resultCode: Int) {
                if (resultCode == 1000 && routeResult != null) {
                    result.success(mapOf(
                        "paths" to routeResult.paths.map { path: DrivePath ->
                            mapOf(
                                "distance" to path.distance.toDouble(),
                                "duration" to path.duration.toDouble(),
                                "strategy" to path.strategy,
                                "tolls" to path.tolls.toDouble(),
                                "tollDistance" to path.tollDistance.toDouble(),
                                "trafficLights" to path.totalTrafficlights,
                                "steps" to path.steps.map { step ->
                                    mapOf(
                                        "instruction" to step.instruction,
                                        "road" to step.road,
                                        "distance" to step.distance.toDouble(),
                                        "duration" to step.duration.toDouble(),
                                        "action" to step.action,
                                        "path" to step.polyline.map { pt ->
                                            mapOf("latitude" to pt.latitude, "longitude" to pt.longitude)
                                        }
                                    )
                                }
                            )
                        }
                    ))
                } else {
                    result.error("ROUTE_ERROR_$resultCode", "Driving route failed", null)
                }
            }
            override fun onBusRouteSearched(p0: com.amap.api.services.route.BusRouteResult?, p1: Int) {}
            override fun onRideRouteSearched(p0: com.amap.api.services.route.RideRouteResult?, p1: Int) {}
            override fun onWalkRouteSearched(walkResult: WalkRouteResult?, resultCode: Int) {}
        })
        search.calculateDriveRouteAsyn(query)
    }

    private fun walkingRoute(args: Map<String, Any>, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val originMap = args["origin"] as Map<String, Any>
        @Suppress("UNCHECKED_CAST")
        val destMap = args["destination"] as Map<String, Any>
        val origin = LatLonPoint(
            (originMap["latitude"] as Number).toDouble(),
            (originMap["longitude"] as Number).toDouble()
        )
        val dest = LatLonPoint(
            (destMap["latitude"] as Number).toDouble(),
            (destMap["longitude"] as Number).toDouble()
        )

        val search = RouteSearch(context)
        val fromAndTo = RouteSearch.FromAndTo(origin, dest)
        val query = RouteSearch.WalkRouteQuery(fromAndTo, RouteSearch.WALK_DEFAULT)
        search.setRouteSearchListener(object : RouteSearch.OnRouteSearchListener {
            override fun onDriveRouteSearched(p0: DriveRouteResult?, p1: Int) {}
            override fun onBusRouteSearched(p0: com.amap.api.services.route.BusRouteResult?, p1: Int) {}
            override fun onRideRouteSearched(p0: com.amap.api.services.route.RideRouteResult?, p1: Int) {}
            override fun onWalkRouteSearched(walkResult: WalkRouteResult?, resultCode: Int) {
                if (resultCode == 1000 && walkResult != null) {
                    result.success(mapOf(
                        "paths" to walkResult.paths.map { path: WalkPath ->
                            mapOf(
                                "distance" to path.distance.toDouble(),
                                "duration" to path.duration.toDouble(),
                                "steps" to path.steps.map { step ->
                                    mapOf(
                                        "instruction" to step.instruction,
                                        "road" to step.road,
                                        "distance" to step.distance.toDouble(),
                                        "duration" to step.duration.toDouble(),
                                        "action" to step.action,
                                        "path" to step.polyline.map { pt ->
                                            mapOf("latitude" to pt.latitude, "longitude" to pt.longitude)
                                        }
                                    )
                                }
                            )
                        }
                    ))
                } else {
                    result.error("ROUTE_ERROR_$resultCode", "Walking route failed", null)
                }
            }
        })
        search.calculateWalkRouteAsyn(query)
    }

    private fun searchDistrict(args: Map<String, Any>, result: MethodChannel.Result) {
        val keywords = args["keywords"] as String
        val level = (args["level"] as? Int) ?: 3
        val search = DistrictSearch(context)
        val query = DistrictSearchQuery()
        query.keywords = keywords
        search.query = query
        search.setOnDistrictSearchListener(object : DistrictSearch.OnDistrictSearchListener {
            override fun onDistrictSearched(districtResult: DistrictResult?) {
                val items = districtResult?.district?.firstOrNull()?.subDistrict
                    ?.map { convertDistrictItem(it) } ?: emptyList()
                result.success(items)
            }
        })
        search.searchDistrictAsyn()
    }

    private fun convertDistrictItem(item: DistrictItem): Map<String, Any?> {
        val center = item.center
        return mapOf(
            "name" to item.name,
            "adCode" to item.adcode,
            "cityCode" to item.citycode,
            "level" to item.level,
            "latitude" to center?.latitude,
            "longitude" to center?.longitude,
            "districts" to (item.subDistrict?.map { convertDistrictItem(it) } ?: emptyList<Map<String, Any?>>()),
        )
    }

    private fun poiResultToMap(poiResult: PoiResult, page: Int): Map<String, Any> = mapOf(
        "pois" to poiResult.pois.map { poi ->
            mapOf(
                "poiId" to poi.poiId,
                "title" to poi.title,
                "typeDes" to poi.typeDes,
                "typeCode" to poi.typeCode,
                "latitude" to poi.latLonPoint?.latitude,
                "longitude" to poi.latLonPoint?.longitude,
                "address" to poi.snippet,
                "tel" to poi.tel,
                "distance" to poi.distance.toDouble(),
                "cityName" to poi.cityName,
                "adName" to poi.adName,
                "snippet" to poi.snippet,
            )
        },
        "totalCount" to (poiResult.query?.pageSize?.let { it * poiResult.pageCount } ?: 0),
        "pageCount" to poiResult.pageCount,
        "pageNum" to page,
    )
}
