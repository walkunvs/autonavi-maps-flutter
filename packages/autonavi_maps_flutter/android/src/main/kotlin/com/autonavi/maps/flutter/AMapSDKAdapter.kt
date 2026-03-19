package com.autonavi.maps.flutter

import android.content.Context
import android.view.View
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.CoordinateConverter
import com.amap.api.maps.TextureMapView
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.Circle
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.Polygon
import com.amap.api.maps.model.Polyline

/**
 * Adapter that isolates all AMap 3D Maps SDK calls.
 * When upgrading the AMap 3D Map SDK, only this file needs changes.
 */
class AMapSDKAdapter(context: Context) :
    AMap.OnCameraChangeListener,
    AMap.OnMapClickListener,
    AMap.OnMapLongClickListener,
    AMap.OnMarkerClickListener {

    // MARK: - Event callbacks (no SDK types in signatures)

    var onCameraMove:   ((Map<String, Any>) -> Unit)? = null
    var onCameraIdle:   (() -> Unit)? = null
    var onMapTap:       ((Map<String, Any>) -> Unit)? = null
    var onMapLongPress: ((Map<String, Any>) -> Unit)? = null
    var onMarkerTap:    ((String) -> Unit)? = null   // markerId

    // MARK: - Private SDK state

    private val mapView = TextureMapView(context)
    private val aMap: AMap get() = mapView.map
    private val markers   = mutableMapOf<String, Marker>()
    private val polylines = mutableMapOf<String, Polyline>()
    private val polygons  = mutableMapOf<String, Polygon>()
    private val circles   = mutableMapOf<String, Circle>()

    init {
        mapView.onCreate(null)
        // TextureMapView requires onResume() to start the render loop and
        // tile-loading pipeline.  Unlike GLSurfaceView (MapView), it does not
        // auto-start its render thread; without this call the map stays black.
        mapView.onResume()
        aMap.addOnCameraChangeListener(this)
        aMap.setOnMapClickListener(this)
        aMap.setOnMapLongClickListener(this)
        aMap.setOnMarkerClickListener(this)
    }

    // MARK: - Native view

    fun nativeView(): View = mapView

    fun pause() {
        mapView.onPause()
    }

    fun destroy() {
        mapView.onPause()
        mapView.onDestroy()
    }

    // MARK: - Camera

    fun applyInitialCamera(json: Map<String, Any>) {
        val pos = Convert.toCameraPosition(json)
        aMap.moveCamera(CameraUpdateFactory.newCameraPosition(pos))
    }

    fun applyCameraUpdate(json: Map<*, *>, animated: Boolean) {
        val update = buildCameraUpdate(json) ?: return
        if (animated) aMap.animateCamera(update) else aMap.moveCamera(update)
    }

    fun currentCameraPosition(): Map<String, Any> = Convert.fromCameraPosition(aMap.cameraPosition)

    // MARK: - Projection

    fun latLng(x: Int, y: Int): Map<String, Any> =
        Convert.fromLatLng(aMap.projection.fromScreenLocation(android.graphics.Point(x, y)))

    fun screenCoordinate(json: Map<*, *>): Map<String, Int> {
        val pt = aMap.projection.toScreenLocation(Convert.toLatLng(json))
        return mapOf("x" to pt.x, "y" to pt.y)
    }

    // MARK: - Snapshot

    fun takeSnapshot(onResult: (ByteArray?) -> Unit) {
        aMap.getMapScreenShot(object : AMap.OnMapScreenShotListener {
            override fun onMapScreenShot(bitmap: android.graphics.Bitmap?) {
                if (bitmap == null) { onResult(null); return }
                val stream = java.io.ByteArrayOutputStream()
                bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                onResult(stream.toByteArray())
            }
            override fun onMapScreenShot(bitmap: android.graphics.Bitmap?, status: Int) {}
        })
    }

    // MARK: - Map options

    fun applyOptions(options: Map<String, Any>) {
        val ui = aMap.uiSettings
        (options["mapType"]             as? Int)?.let     { aMap.mapType = Convert.toMapType(it) }
        (options["compassEnabled"]       as? Boolean)?.let { ui.isCompassEnabled = it }
        (options["trafficEnabled"]       as? Boolean)?.let { aMap.isTrafficEnabled = it }
        (options["buildingsEnabled"]     as? Boolean)?.let { aMap.showBuildings(it) }
        (options["myLocationEnabled"]    as? Boolean)?.let { aMap.isMyLocationEnabled = it }
        (options["zoomControlsEnabled"]  as? Boolean)?.let { ui.isZoomControlsEnabled = it }
        (options["rotateGesturesEnabled"] as? Boolean)?.let { ui.isRotateGesturesEnabled = it }
        (options["scrollGesturesEnabled"] as? Boolean)?.let { ui.isScrollGesturesEnabled = it }
        (options["tiltGesturesEnabled"]  as? Boolean)?.let { ui.isTiltGesturesEnabled = it }
        (options["zoomGesturesEnabled"]  as? Boolean)?.let { ui.isZoomGesturesEnabled = it }
        @Suppress("UNCHECKED_CAST")
        (options["minMaxZoomPreference"] as? Map<String, Any>)?.let { mm ->
            (mm["minZoom"] as? Number)?.toFloat()?.let { aMap.setMinZoomLevel(it) }
            (mm["maxZoom"] as? Number)?.toFloat()?.let { aMap.setMaxZoomLevel(it) }
        }
    }

    // MARK: - Markers

    @Suppress("UNCHECKED_CAST")
    fun addMarker(json: Map<*, *>) {
        val markerId = json["markerId"] as String
        val opts = Convert.toMarkerOptions(json)
        val iw = json["infoWindow"] as? Map<*, *>
        opts.title(iw?.get("title") as? String ?: "")
        opts.snippet(iw?.get("snippet") as? String)
        markers[markerId] = aMap.addMarker(opts)
    }

    @Suppress("UNCHECKED_CAST")
    fun handleMarkerUpdates(args: Map<*, *>) {
        (args["markersToAdd"]    as? List<Map<*, *>>)?.forEach { addMarker(it) }
        (args["markersToChange"] as? List<Map<*, *>>)?.forEach { j ->
            val id = j["markerId"] as String
            markers[id]?.remove()
            addMarker(j)
        }
        (args["markerIdsToRemove"] as? List<String>)?.forEach { id -> markers.remove(id)?.remove() }
    }

    fun showInfoWindow(markerId: String)    { markers[markerId]?.showInfoWindow() }
    fun hideInfoWindow(markerId: String)    { markers[markerId]?.hideInfoWindow() }
    fun isInfoWindowShown(markerId: String) = markers[markerId]?.isInfoWindowShown ?: false

    // MARK: - Polylines

    @Suppress("UNCHECKED_CAST")
    fun handlePolylineUpdates(args: Map<*, *>) {
        (args["polylinesToAdd"]    as? List<Map<*, *>>)?.forEach { j ->
            val id = j["polylineId"] as String; polylines[id] = aMap.addPolyline(Convert.toPolylineOptions(j))
        }
        (args["polylinesToChange"] as? List<Map<*, *>>)?.forEach { j ->
            val id = j["polylineId"] as String; polylines.remove(id)?.remove()
            polylines[id] = aMap.addPolyline(Convert.toPolylineOptions(j))
        }
        (args["polylineIdsToRemove"] as? List<String>)?.forEach { id -> polylines.remove(id)?.remove() }
    }

    // MARK: - Polygons

    @Suppress("UNCHECKED_CAST")
    fun handlePolygonUpdates(args: Map<*, *>) {
        (args["polygonsToAdd"]    as? List<Map<*, *>>)?.forEach { j ->
            val id = j["polygonId"] as String; polygons[id] = aMap.addPolygon(Convert.toPolygonOptions(j))
        }
        (args["polygonsToChange"] as? List<Map<*, *>>)?.forEach { j ->
            val id = j["polygonId"] as String; polygons.remove(id)?.remove()
            polygons[id] = aMap.addPolygon(Convert.toPolygonOptions(j))
        }
        (args["polygonIdsToRemove"] as? List<String>)?.forEach { id -> polygons.remove(id)?.remove() }
    }

    // MARK: - Circles

    @Suppress("UNCHECKED_CAST")
    fun handleCircleUpdates(args: Map<*, *>) {
        (args["circlesToAdd"]    as? List<Map<*, *>>)?.forEach { j ->
            val id = j["circleId"] as String; circles[id] = aMap.addCircle(Convert.toCircleOptions(j))
        }
        (args["circlesToChange"] as? List<Map<*, *>>)?.forEach { j ->
            val id = j["circleId"] as String; circles.remove(id)?.remove()
            circles[id] = aMap.addCircle(Convert.toCircleOptions(j))
        }
        (args["circleIdsToRemove"] as? List<String>)?.forEach { id -> circles.remove(id)?.remove() }
    }

    // MARK: - Coordinate conversion

    fun convertFromWGS84(json: Map<*, *>): Map<String, Any> {
        val wgs84 = Convert.toLatLng(json)
        val converter = CoordinateConverter(mapView.context)
        converter.from(CoordinateConverter.CoordType.GPS)
        converter.coord(wgs84)
        return Convert.fromLatLng(converter.convert())
    }

    // MARK: - AMap listeners

    override fun onCameraChange(position: CameraPosition) {
        onCameraMove?.invoke(Convert.fromCameraPosition(position))
    }

    override fun onCameraChangeFinish(position: CameraPosition) {
        onCameraIdle?.invoke()
    }

    override fun onMapClick(latLng: LatLng) {
        onMapTap?.invoke(Convert.fromLatLng(latLng))
    }

    override fun onMapLongClick(latLng: LatLng) {
        onMapLongPress?.invoke(Convert.fromLatLng(latLng))
    }

    override fun onMarkerClick(marker: Marker): Boolean {
        val markerId = markers.entries.firstOrNull { it.value == marker }?.key
        if (markerId != null) onMarkerTap?.invoke(markerId)
        return marker.isInfoWindowShown.not()
    }

    // MARK: - Private

    @Suppress("UNCHECKED_CAST")
    private fun buildCameraUpdate(json: Map<*, *>): com.amap.api.maps.CameraUpdate? {
        json["newCameraPosition"]?.let {
            return CameraUpdateFactory.newCameraPosition(Convert.toCameraPosition(it as Map<*, *>))
        }
        json["newLatLng"]?.let {
            return CameraUpdateFactory.newLatLng(Convert.toLatLng(it as Map<*, *>))
        }
        json["newLatLngZoom"]?.let { lz ->
            val lzMap = lz as Map<*, *>
            return CameraUpdateFactory.newLatLngZoom(
                Convert.toLatLng(lzMap["latLng"] as Map<*, *>),
                (lzMap["zoom"] as Number).toFloat()
            )
        }
        json["zoomTo"]?.let { return CameraUpdateFactory.zoomTo((it as Number).toFloat()) }
        json["zoomIn"]?.let { return CameraUpdateFactory.zoomIn() }
        json["zoomOut"]?.let { return CameraUpdateFactory.zoomOut() }
        json["zoomBy"]?.let { return CameraUpdateFactory.zoomBy((it as Number).toFloat()) }
        json["scrollBy"]?.let {
            val sb = it as Map<*, *>
            return CameraUpdateFactory.scrollBy(
                (sb["dx"] as Number).toFloat(), (sb["dy"] as Number).toFloat()
            )
        }
        json["newLatLngBounds"]?.let { nb ->
            val nbMap = nb as Map<*, *>
            val boundsMap = nbMap["bounds"] as Map<*, *>
            val bounds = LatLngBounds.Builder()
                .include(Convert.toLatLng(boundsMap["southwest"] as Map<*, *>))
                .include(Convert.toLatLng(boundsMap["northeast"] as Map<*, *>))
                .build()
            return CameraUpdateFactory.newLatLngBounds(bounds, (nbMap["padding"] as? Number)?.toInt() ?: 0)
        }
        return null
    }
}
