package com.autonavi.maps.flutter

import android.graphics.Color
import com.amap.api.maps.AMap
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.CircleOptions
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.PolygonOptions
import com.amap.api.maps.model.PolylineOptions

object Convert {

    fun toLatLng(json: Map<*, *>): LatLng {
        val lat = (json["latitude"] as Number).toDouble()
        val lng = (json["longitude"] as Number).toDouble()
        return LatLng(lat, lng)
    }

    fun fromLatLng(latLng: LatLng): Map<String, Double> =
        mapOf("latitude" to latLng.latitude, "longitude" to latLng.longitude)

    fun toCameraPosition(json: Map<*, *>): CameraPosition {
        val target = toLatLng(json["target"] as Map<*, *>)
        val bearing = (json["bearing"] as? Number)?.toFloat() ?: 0f
        val tilt = (json["tilt"] as? Number)?.toFloat() ?: 0f
        val zoom = (json["zoom"] as? Number)?.toFloat() ?: 10f
        return CameraPosition(target, zoom, tilt, bearing)
    }

    fun fromCameraPosition(cameraPosition: CameraPosition): Map<String, Any> = mapOf(
        "target" to fromLatLng(cameraPosition.target),
        "bearing" to cameraPosition.bearing.toDouble(),
        "tilt" to cameraPosition.tilt.toDouble(),
        "zoom" to cameraPosition.zoom.toDouble(),
    )

    fun toMarkerOptions(json: Map<*, *>): MarkerOptions {
        val options = MarkerOptions()
        options.position(toLatLng(json["position"] as Map<*, *>))
        options.alpha((json["alpha"] as? Number)?.toFloat() ?: 1f)
        options.draggable(json["draggable"] as? Boolean ?: false)
        options.visible(json["visible"] as? Boolean ?: true)
        options.zIndex((json["zIndex"] as? Number)?.toFloat() ?: 0f)

        val iconJson = json["icon"] as? Map<*, *>
        if (iconJson != null) {
            val iconType = iconJson["type"] as? String
            when (iconType) {
                "defaultMarkerWithHue" -> {
                    val hue = (iconJson["hue"] as? Number)?.toFloat() ?: 0f
                    options.icon(BitmapDescriptorFactory.defaultMarker(hue))
                }
                else -> options.icon(BitmapDescriptorFactory.defaultMarker())
            }
        }

        return options
    }

    fun toPolylineOptions(json: Map<*, *>): PolylineOptions {
        val options = PolylineOptions()
        @Suppress("UNCHECKED_CAST")
        val points = json["points"] as? List<Map<*, *>> ?: emptyList()
        points.forEach { options.add(toLatLng(it)) }
        options.color((json["color"] as? Number)?.toInt() ?: Color.BLACK)
        options.width((json["width"] as? Number)?.toFloat() ?: 10f)
        options.visible(json["visible"] as? Boolean ?: true)
        options.zIndex((json["zIndex"] as? Number)?.toFloat() ?: 0f)
        options.geodesic(json["geodesic"] as? Boolean ?: false)
        return options
    }

    fun toPolygonOptions(json: Map<*, *>): PolygonOptions {
        val options = PolygonOptions()
        @Suppress("UNCHECKED_CAST")
        val points = json["points"] as? List<Map<*, *>> ?: emptyList()
        points.forEach { options.add(toLatLng(it)) }
        options.fillColor((json["fillColor"] as? Number)?.toInt() ?: Color.TRANSPARENT)
        options.strokeColor((json["strokeColor"] as? Number)?.toInt() ?: Color.BLACK)
        options.strokeWidth((json["strokeWidth"] as? Number)?.toFloat() ?: 10f)
        options.visible(json["visible"] as? Boolean ?: true)
        options.zIndex((json["zIndex"] as? Number)?.toFloat() ?: 0f)
        return options
    }

    fun toCircleOptions(json: Map<*, *>): CircleOptions {
        val options = CircleOptions()
        options.center(toLatLng(json["center"] as Map<*, *>))
        options.radius((json["radius"] as? Number)?.toDouble() ?: 0.0)
        options.fillColor((json["fillColor"] as? Number)?.toInt() ?: Color.TRANSPARENT)
        options.strokeColor((json["strokeColor"] as? Number)?.toInt() ?: Color.BLACK)
        options.strokeWidth((json["strokeWidth"] as? Number)?.toFloat() ?: 10f)
        options.visible(json["visible"] as? Boolean ?: true)
        options.zIndex((json["zIndex"] as? Number)?.toFloat() ?: 0f)
        return options
    }

    fun toMapType(index: Int): Int = when (index) {
        1 -> AMap.MAP_TYPE_SATELLITE
        2 -> AMap.MAP_TYPE_NIGHT
        3 -> AMap.MAP_TYPE_NAVI
        4 -> AMap.MAP_TYPE_BUS
        else -> AMap.MAP_TYPE_NORMAL
    }
}
