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

/**
 * Adapter that isolates all AMap Search SDK calls.
 * When upgrading the AMap Search SDK, only this file needs changes.
 */
class AMapSearchAdapter(private val context: Context) {

    // MARK: - Plain data types (no SDK types exposed)

    data class POIItem(
        val poiId: String?, val title: String?, val typeDes: String?, val typeCode: String?,
        val latitude: Double?, val longitude: Double?, val address: String?, val tel: String?,
        val distance: Double, val cityName: String?, val adName: String?,
    )

    data class POIPage(val pois: List<POIItem>, val totalCount: Int, val pageCount: Int, val pageNum: Int)

    data class AddressComponent(
        val formattedAddress: String?, val country: String?, val province: String?,
        val city: String?, val cityCode: String?, val district: String?, val adCode: String?,
        val street: String?, val streetNumber: String?, val township: String?, val townCode: String?,
    )

    data class GeocodeItem(
        val formattedAddress: String?, val country: String?, val province: String?,
        val city: String?, val district: String?, val adCode: String?,
        val latitude: Double?, val longitude: Double?, val level: String?,
    )

    data class RouteStep(
        val instruction: String?, val road: String?,
        val distance: Double, val duration: Double,
        val action: String?, val path: List<Map<String, Double>>,
    )

    data class RoutePath(
        val distance: Double, val duration: Double, val strategy: String?,
        val tolls: Double, val tollDistance: Double, val trafficLights: Int,
        val steps: List<RouteStep>,
    )

    data class DistrictNode(
        val name: String?, val adCode: String?, val cityCode: String?, val level: String?,
        val latitude: Double?, val longitude: Double?, val districts: List<DistrictNode>,
    )

    // MARK: - Public API

    fun searchKeyword(
        keyword: String, city: String, types: String,
        page: Int, pageSize: Int,
        callback: (POIPage?, Pair<String, String?>?) -> Unit,
    ) {
        val query = PoiSearch.Query(keyword, types, city).apply {
            pageNum = page - 1; this.pageSize = pageSize
        }
        PoiSearch(context, query).apply {
            setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
                override fun onPoiSearched(result: PoiResult?, code: Int) {
                    if (code == 1000 && result != null) callback(poiResultToPage(result, page), null)
                    else callback(null, "SEARCH_ERROR_$code" to "POI search failed")
                }
                override fun onPoiItemSearched(item: PoiItem?, code: Int) {}
            })
            searchPOIAsyn()
        }
    }

    fun searchNearby(
        lat: Double, lng: Double, radius: Int,
        keyword: String, types: String,
        page: Int, pageSize: Int,
        callback: (POIPage?, Pair<String, String?>?) -> Unit,
    ) {
        val query = PoiSearch.Query(keyword, types, "").apply {
            pageNum = page - 1; this.pageSize = pageSize
        }
        PoiSearch(context, query).apply {
            bound = PoiSearch.SearchBound(LatLonPoint(lat, lng), radius)
            setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
                override fun onPoiSearched(result: PoiResult?, code: Int) {
                    if (code == 1000 && result != null) callback(poiResultToPage(result, page), null)
                    else callback(null, "SEARCH_ERROR_$code" to "Nearby search failed")
                }
                override fun onPoiItemSearched(item: PoiItem?, code: Int) {}
            })
            searchPOIAsyn()
        }
    }

    fun regeocode(lat: Double, lng: Double, callback: (AddressComponent?, Pair<String, String?>?) -> Unit) {
        GeocodeSearch(context).apply {
            setOnGeocodeSearchListener(object : GeocodeSearch.OnGeocodeSearchListener {
                override fun onRegeocodeSearched(result: RegeocodeResult?, code: Int) {
                    if (code == 1000 && result != null) {
                        val addr = result.regeocodeAddress
                        callback(AddressComponent(
                            formattedAddress = addr.formatAddress,
                            country = addr.country, province = addr.province,
                            city = addr.city, cityCode = addr.cityCode,
                            district = addr.district, adCode = addr.adCode,
                            street = addr.streetNumber?.street,
                            streetNumber = addr.streetNumber?.number,
                            township = addr.township, townCode = addr.towncode,
                        ), null)
                    } else {
                        callback(null, "REGEOCODE_ERROR_$code" to "Regeocode failed")
                    }
                }
                override fun onGeocodeSearched(result: GeocodeResult?, code: Int) {}
            })
            getFromLocationAsyn(RegeocodeQuery(LatLonPoint(lat, lng), 200f, GeocodeSearch.AMAP))
        }
    }

    fun geocode(address: String, city: String, callback: (List<GeocodeItem>?, Pair<String, String?>?) -> Unit) {
        GeocodeSearch(context).apply {
            setOnGeocodeSearchListener(object : GeocodeSearch.OnGeocodeSearchListener {
                override fun onRegeocodeSearched(result: RegeocodeResult?, code: Int) {}
                override fun onGeocodeSearched(result: GeocodeResult?, code: Int) {
                    if (code == 1000 && result != null) {
                        val items = result.geocodeAddressList?.map { addr: GeocodeAddress ->
                            GeocodeItem(
                                formattedAddress = addr.formatAddress,
                                country = addr.country, province = addr.province,
                                city = addr.city, district = addr.district,
                                adCode = addr.adcode,
                                latitude = addr.latLonPoint?.latitude,
                                longitude = addr.latLonPoint?.longitude,
                                level = addr.level,
                            )
                        } ?: emptyList()
                        callback(items, null)
                    } else {
                        callback(null, "GEOCODE_ERROR_$code" to "Geocode failed")
                    }
                }
            })
            getFromLocationNameAsyn(GeocodeQuery(address, city))
        }
    }

    fun drivingRoute(
        originLat: Double, originLng: Double,
        destLat: Double, destLng: Double,
        waypoints: List<Pair<Double, Double>>,
        callback: (List<RoutePath>?, Pair<String, String?>?) -> Unit,
    ) {
        val origin = LatLonPoint(originLat, originLng)
        val dest   = LatLonPoint(destLat, destLng)
        val waypointList = waypoints.map { LatLonPoint(it.first, it.second) }
            .takeIf { it.isNotEmpty() }

        val search = RouteSearch(context)
        val fromAndTo = RouteSearch.FromAndTo(origin, dest)
        val query = RouteSearch.DriveRouteQuery(fromAndTo, RouteSearch.DrivingDefault, waypointList, null, "")
        search.setRouteSearchListener(object : RouteSearch.OnRouteSearchListener {
            override fun onDriveRouteSearched(result: DriveRouteResult?, code: Int) {
                if (code == 1000 && result != null) {
                    callback(result.paths.map { drivePathToRoutePath(it) }, null)
                } else {
                    callback(null, "ROUTE_ERROR_$code" to "Driving route failed")
                }
            }
            override fun onBusRouteSearched(p0: com.amap.api.services.route.BusRouteResult?, p1: Int) {}
            override fun onRideRouteSearched(p0: com.amap.api.services.route.RideRouteResult?, p1: Int) {}
            override fun onWalkRouteSearched(p0: WalkRouteResult?, p1: Int) {}
        })
        search.calculateDriveRouteAsyn(query)
    }

    fun walkingRoute(
        originLat: Double, originLng: Double,
        destLat: Double, destLng: Double,
        callback: (List<RoutePath>?, Pair<String, String?>?) -> Unit,
    ) {
        val origin = LatLonPoint(originLat, originLng)
        val dest   = LatLonPoint(destLat, destLng)
        val search = RouteSearch(context)
        val query  = RouteSearch.WalkRouteQuery(RouteSearch.FromAndTo(origin, dest), RouteSearch.WALK_DEFAULT)
        search.setRouteSearchListener(object : RouteSearch.OnRouteSearchListener {
            override fun onDriveRouteSearched(p0: DriveRouteResult?, p1: Int) {}
            override fun onBusRouteSearched(p0: com.amap.api.services.route.BusRouteResult?, p1: Int) {}
            override fun onRideRouteSearched(p0: com.amap.api.services.route.RideRouteResult?, p1: Int) {}
            override fun onWalkRouteSearched(result: WalkRouteResult?, code: Int) {
                if (code == 1000 && result != null) {
                    callback(result.paths.map { walkPathToRoutePath(it) }, null)
                } else {
                    callback(null, "ROUTE_ERROR_$code" to "Walking route failed")
                }
            }
        })
        search.calculateWalkRouteAsyn(query)
    }

    fun searchDistrict(keywords: String, callback: (List<DistrictNode>?, Pair<String, String?>?) -> Unit) {
        DistrictSearch(context).apply {
            query = DistrictSearchQuery().also { it.keywords = keywords }
            setOnDistrictSearchListener(object : DistrictSearch.OnDistrictSearchListener {
                override fun onDistrictSearched(result: DistrictResult?) {
                    val items = result?.district?.firstOrNull()?.subDistrict
                        ?.map { convertDistrict(it) } ?: emptyList()
                    callback(items, null)
                }
            })
            searchDistrictAsyn()
        }
    }

    // MARK: - Private converters

    private fun poiResultToPage(result: PoiResult, page: Int): POIPage {
        val pois = result.pois.map { poi ->
            POIItem(
                poiId = poi.poiId, title = poi.title, typeDes = poi.typeDes,
                typeCode = poi.typeCode,
                latitude  = poi.latLonPoint?.latitude,
                longitude = poi.latLonPoint?.longitude,
                address = poi.snippet, tel = poi.tel,
                distance = poi.distance.toDouble(),
                cityName = poi.cityName, adName = poi.adName,
            )
        }
        val total = (result.query?.pageSize ?: 0) * result.pageCount
        return POIPage(pois = pois, totalCount = total, pageCount = result.pageCount, pageNum = page)
    }

    private fun drivePathToRoutePath(path: DrivePath): RoutePath = RoutePath(
        distance = path.distance.toDouble(), duration = path.duration.toDouble(),
        strategy = path.strategy, tolls = path.tolls.toDouble(),
        tollDistance = path.tollDistance.toDouble(), trafficLights = path.totalTrafficlights,
        steps = path.steps.map { step ->
            RouteStep(
                instruction = step.instruction, road = step.road,
                distance = step.distance.toDouble(), duration = step.duration.toDouble(),
                action = step.action,
                path = step.polyline.map { pt -> mapOf("latitude" to pt.latitude, "longitude" to pt.longitude) },
            )
        },
    )

    private fun walkPathToRoutePath(path: WalkPath): RoutePath = RoutePath(
        distance = path.distance.toDouble(), duration = path.duration.toDouble(),
        strategy = null, tolls = 0.0, tollDistance = 0.0, trafficLights = 0,
        steps = path.steps.map { step ->
            RouteStep(
                instruction = step.instruction, road = step.road,
                distance = step.distance.toDouble(), duration = step.duration.toDouble(),
                action = step.action,
                path = step.polyline.map { pt -> mapOf("latitude" to pt.latitude, "longitude" to pt.longitude) },
            )
        },
    )

    private fun convertDistrict(item: DistrictItem): DistrictNode = DistrictNode(
        name = item.name, adCode = item.adcode, cityCode = item.citycode, level = item.level,
        latitude  = item.center?.latitude,
        longitude = item.center?.longitude,
        districts = item.subDistrict?.map { convertDistrict(it) } ?: emptyList(),
    )
}
