package com.autonavi.maps.flutter

import android.content.Context
import android.view.View
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapView
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.Circle
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.Polygon
import com.amap.api.maps.model.Polyline
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class AMapController(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String, Any>,
) : PlatformView, MethodChannel.MethodCallHandler,
    AMap.OnCameraChangeListener, AMap.OnMapClickListener, AMap.OnMapLongClickListener,
    AMap.OnMarkerClickListener {

    private val mapView = MapView(context)
    private val aMap: AMap get() = mapView.map
    private val channel = MethodChannel(messenger, "plugins.autonavi.flutter/amap_map_$viewId")

    private val markers = mutableMapOf<String, Marker>()
    private val polylines = mutableMapOf<String, Polyline>()
    private val polygons = mutableMapOf<String, Polygon>()
    private val circles = mutableMapOf<String, Circle>()

    init {
        mapView.onCreate(null)
        channel.setMethodCallHandler(this)

        @Suppress("UNCHECKED_CAST")
        val initialCamera = params["initialCameraPosition"] as? Map<String, Any>
        if (initialCamera != null) {
            val cameraPosition = Convert.toCameraPosition(initialCamera)
            aMap.moveCamera(CameraUpdateFactory.newCameraPosition(cameraPosition))
        }

        @Suppress("UNCHECKED_CAST")
        val options = params["options"] as? Map<String, Any>
        if (options != null) applyMapOptions(options)

        @Suppress("UNCHECKED_CAST")
        val markersToAdd = params["markersToAdd"] as? List<Map<String, Any>>
        markersToAdd?.forEach { addMarker(it) }

        @Suppress("UNCHECKED_CAST")
        val polylinesToAdd = params["polylinesToAdd"] as? List<Map<String, Any>>
        polylinesToAdd?.forEach { addPolyline(it) }

        @Suppress("UNCHECKED_CAST")
        val polygonsToAdd = params["polygonsToAdd"] as? List<Map<String, Any>>
        polygonsToAdd?.forEach { addPolygon(it) }

        @Suppress("UNCHECKED_CAST")
        val circlesToAdd = params["circlesToAdd"] as? List<Map<String, Any>>
        circlesToAdd?.forEach { addCircle(it) }

        aMap.addOnCameraChangeListener(this)
        aMap.setOnMapClickListener(this)
        aMap.setOnMapLongClickListener(this)
        aMap.setOnMarkerClickListener(this)
    }

    override fun getView(): View = mapView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        mapView.onDestroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "map#update" -> {
                @Suppress("UNCHECKED_CAST")
                val options = call.argument<Map<String, Any>>("options")
                if (options != null) applyMapOptions(options)
                result.success(null)
            }
            "map#moveCamera" -> {
                val update = buildCameraUpdate(call.arguments as Map<*, *>)
                if (update != null) aMap.moveCamera(update)
                result.success(null)
            }
            "map#animateCamera" -> {
                val update = buildCameraUpdate(call.arguments as Map<*, *>)
                if (update != null) aMap.animateCamera(update)
                result.success(null)
            }
            "map#getCameraPosition" -> {
                result.success(Convert.fromCameraPosition(aMap.cameraPosition))
            }
            "map#getLatLng" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<*, *>
                val x = (args["x"] as Number).toInt()
                val y = (args["y"] as Number).toInt()
                val latLng = aMap.projection.fromScreenLocation(
                    android.graphics.Point(x, y)
                )
                result.success(Convert.fromLatLng(latLng))
            }
            "map#getScreenCoordinate" -> {
                @Suppress("UNCHECKED_CAST")
                val latLng = Convert.toLatLng(call.arguments as Map<*, *>)
                val point = aMap.projection.toScreenLocation(latLng)
                result.success(mapOf("x" to point.x, "y" to point.y))
            }
            "map#takeSnapshot" -> {
                aMap.getMapScreenShot { bitmap ->
                    if (bitmap == null) {
                        result.success(null)
                        return@getMapScreenShot
                    }
                    val stream = java.io.ByteArrayOutputStream()
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                    result.success(stream.toByteArray())
                }
            }
            "markers#update" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<*, *>
                handleMarkerUpdates(args)
                result.success(null)
            }
            "markers#showInfoWindow" -> {
                val markerId = call.argument<String>("markerId")
                markers[markerId]?.showInfoWindow()
                result.success(null)
            }
            "markers#hideInfoWindow" -> {
                val markerId = call.argument<String>("markerId")
                markers[markerId]?.hideInfoWindow()
                result.success(null)
            }
            "markers#isInfoWindowShown" -> {
                val markerId = call.argument<String>("markerId")
                result.success(markers[markerId]?.isInfoWindowShown ?: false)
            }
            "polylines#update" -> {
                @Suppress("UNCHECKED_CAST")
                handlePolylineUpdates(call.arguments as Map<*, *>)
                result.success(null)
            }
            "polygons#update" -> {
                @Suppress("UNCHECKED_CAST")
                handlePolygonUpdates(call.arguments as Map<*, *>)
                result.success(null)
            }
            "circles#update" -> {
                @Suppress("UNCHECKED_CAST")
                handleCircleUpdates(call.arguments as Map<*, *>)
                result.success(null)
            }
            "coordinate#convertFromWGS84" -> {
                @Suppress("UNCHECKED_CAST")
                val wgs84 = Convert.toLatLng(call.arguments as Map<*, *>)
                val converter = com.amap.api.maps.CoordinateConverter(mapView.context)
                converter.from(com.amap.api.maps.CoordinateConverter.CoordType.GPS)
                converter.coord(wgs84)
                val gcj02 = converter.convert()
                result.success(Convert.fromLatLng(gcj02))
            }
            else -> result.notImplemented()
        }
    }

    // Camera listeners
    override fun onCameraChange(position: CameraPosition) {
        channel.invokeMethod("camera#onMove", Convert.fromCameraPosition(position))
    }

    override fun onCameraChangeFinish(position: CameraPosition) {
        channel.invokeMethod("camera#onIdle", null)
    }

    override fun onMapClick(latLng: LatLng) {
        channel.invokeMethod("map#onTap", Convert.fromLatLng(latLng))
    }

    override fun onMapLongClick(latLng: LatLng) {
        channel.invokeMethod("map#onLongPress", Convert.fromLatLng(latLng))
    }

    override fun onMarkerClick(marker: Marker): Boolean {
        channel.invokeMethod("marker#onTap", mapOf("markerId" to marker.title))
        return marker.isInfoWindowShown.not()
    }

    private fun applyMapOptions(options: Map<String, Any>) {
        val uiSettings = aMap.uiSettings
        (options["mapType"] as? Int)?.let { aMap.mapType = Convert.toMapType(it) }
        (options["compassEnabled"] as? Boolean)?.let { uiSettings.isCompassEnabled = it }
        (options["trafficEnabled"] as? Boolean)?.let { aMap.isTrafficEnabled = it }
        (options["buildingsEnabled"] as? Boolean)?.let { aMap.showBuildings(it) }
        (options["myLocationEnabled"] as? Boolean)?.let { aMap.isMyLocationEnabled = it }
        (options["zoomControlsEnabled"] as? Boolean)?.let { uiSettings.isZoomControlsEnabled = it }
        (options["rotateGesturesEnabled"] as? Boolean)?.let { uiSettings.isRotateGesturesEnabled = it }
        (options["scrollGesturesEnabled"] as? Boolean)?.let { uiSettings.isScrollGesturesEnabled = it }
        (options["tiltGesturesEnabled"] as? Boolean)?.let { uiSettings.isTiltGesturesEnabled = it }
        (options["zoomGesturesEnabled"] as? Boolean)?.let { uiSettings.isZoomGesturesEnabled = it }

        @Suppress("UNCHECKED_CAST")
        val minMax = options["minMaxZoomPreference"] as? Map<String, Any>
        if (minMax != null) {
            val minZoom = (minMax["minZoom"] as? Number)?.toFloat()
            val maxZoom = (minMax["maxZoom"] as? Number)?.toFloat()
            if (minZoom != null) aMap.setMinZoomLevel(minZoom)
            if (maxZoom != null) aMap.setMaxZoomLevel(maxZoom)
        }
    }

    private fun buildCameraUpdate(json: Map<*, *>): com.amap.api.maps.CameraUpdate? {
        json["newCameraPosition"]?.let {
            return CameraUpdateFactory.newCameraPosition(
                Convert.toCameraPosition(it as Map<*, *>)
            )
        }
        json["newLatLng"]?.let {
            return CameraUpdateFactory.newLatLng(Convert.toLatLng(it as Map<*, *>))
        }
        json["newLatLngZoom"]?.let { lz ->
            val lzMap = lz as Map<*, *>
            val latLng = Convert.toLatLng(lzMap["latLng"] as Map<*, *>)
            val zoom = (lzMap["zoom"] as Number).toFloat()
            return CameraUpdateFactory.newLatLngZoom(latLng, zoom)
        }
        json["zoomTo"]?.let {
            return CameraUpdateFactory.zoomTo((it as Number).toFloat())
        }
        json["zoomIn"]?.let { return CameraUpdateFactory.zoomIn() }
        json["zoomOut"]?.let { return CameraUpdateFactory.zoomOut() }
        json["zoomBy"]?.let {
            return CameraUpdateFactory.zoomBy((it as Number).toFloat())
        }
        json["scrollBy"]?.let {
            val sb = it as Map<*, *>
            return CameraUpdateFactory.scrollBy(
                (sb["dx"] as Number).toFloat(),
                (sb["dy"] as Number).toFloat(),
            )
        }
        return null
    }

    @Suppress("UNCHECKED_CAST")
    private fun addMarker(json: Map<*, *>) {
        val markerId = json["markerId"] as String
        val options = Convert.toMarkerOptions(json)
        options.title(markerId)
        val marker = aMap.addMarker(options)
        markers[markerId] = marker
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleMarkerUpdates(args: Map<*, *>) {
        (args["markersToAdd"] as? List<Map<*, *>>)?.forEach { addMarker(it) }
        (args["markersToChange"] as? List<Map<*, *>>)?.forEach { json ->
            val markerId = json["markerId"] as String
            markers[markerId]?.remove()
            addMarker(json)
        }
        (args["markerIdsToRemove"] as? List<String>)?.forEach { id ->
            markers.remove(id)?.remove()
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun addPolyline(json: Map<*, *>) {
        val polylineId = json["polylineId"] as String
        val polyline = aMap.addPolyline(Convert.toPolylineOptions(json))
        polylines[polylineId] = polyline
    }

    @Suppress("UNCHECKED_CAST")
    private fun handlePolylineUpdates(args: Map<*, *>) {
        (args["polylinesToAdd"] as? List<Map<*, *>>)?.forEach { addPolyline(it) }
        (args["polylinesToChange"] as? List<Map<*, *>>)?.forEach { json ->
            val id = json["polylineId"] as String
            polylines.remove(id)?.remove()
            addPolyline(json)
        }
        (args["polylineIdsToRemove"] as? List<String>)?.forEach { id ->
            polylines.remove(id)?.remove()
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun addPolygon(json: Map<*, *>) {
        val polygonId = json["polygonId"] as String
        val polygon = aMap.addPolygon(Convert.toPolygonOptions(json))
        polygons[polygonId] = polygon
    }

    @Suppress("UNCHECKED_CAST")
    private fun handlePolygonUpdates(args: Map<*, *>) {
        (args["polygonsToAdd"] as? List<Map<*, *>>)?.forEach { addPolygon(it) }
        (args["polygonsToChange"] as? List<Map<*, *>>)?.forEach { json ->
            val id = json["polygonId"] as String
            polygons.remove(id)?.remove()
            addPolygon(json)
        }
        (args["polygonIdsToRemove"] as? List<String>)?.forEach { id ->
            polygons.remove(id)?.remove()
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun addCircle(json: Map<*, *>) {
        val circleId = json["circleId"] as String
        val circle = aMap.addCircle(Convert.toCircleOptions(json))
        circles[circleId] = circle
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleCircleUpdates(args: Map<*, *>) {
        (args["circlesToAdd"] as? List<Map<*, *>>)?.forEach { addCircle(it) }
        (args["circlesToChange"] as? List<Map<*, *>>)?.forEach { json ->
            val id = json["circleId"] as String
            circles.remove(id)?.remove()
            addCircle(json)
        }
        (args["circleIdsToRemove"] as? List<String>)?.forEach { id ->
            circles.remove(id)?.remove()
        }
    }
}
